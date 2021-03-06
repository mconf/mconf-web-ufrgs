# -*- coding: utf-8 -*-
# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

require 'uri'
require 'net/http'
require 'mconf/shibboleth'

class ShibbolethController < ApplicationController

  respond_to :html
  layout 'no_sidebar'

  before_filter :check_shib_enabled, :except => [:info]
  before_filter :check_current_user, :except => [:info]
  before_filter :load_shib_session
  before_filter :check_shib_always_new_account, :only => [:create_association]

  # Log in a user using his shibboleth information
  # The application should only reach this point after authenticating using Shibboleth
  # The authentication is currently made with the Apache module mod_shib
  def login

    # to force a redirect back to where the user was
    # needed because the app would block a redirect since the auth is in an external url
    params["return_to"] = user_return_to

    unless @shib.has_basic_info
      logger.error "Shibboleth: couldn't find basic user information from session, " +
        "searching fields #{@shib.basic_info_fields.inspect} " +
        "in: #{@shib.get_data.inspect}"
      @attrs_required = @shib.basic_info_fields
      @attrs_informed = @shib.get_data
      render :attribute_error
    else
      token = @shib.find_and_update_token

      return unless check_active_enrollment(token)

      # there's a token with a user associated
      if token.present? && !token.user_with_disabled.nil?
        user = token.user_with_disabled
        if user.disabled
          logger.info "Shibolleth: user local account is disabled, can't login"
          flash[:error] = t('shibboleth.login.local_account_disabled')
          redirect_to root_path
        else
          # the user is not disabled, logs the user in
          logger.info "Shibboleth: logging in the user #{token.user.inspect}"
          logger.info "Shibboleth: shibboleth data for this user #{@shib.get_data.inspect}"

          # set that the user signed in via shib
          @shib.set_signed_in(user, token)
          # Update user data with the latest version from the federation
          @shib.update_user(token) if current_site.shib_update_users?

          if token.user.active_for_authentication?
            sign_in user
            flash.keep # keep the message set before by #create_association
            redirect_to after_sign_in_path_for(token.user)
          else
            # go to the pending approval page without a flash msg, the page already has a msg
            flash.clear
            redirect_to my_approval_pending_path
          end
        end

      # no token means the user has no association yet, render a page to do it
      else
        if !get_always_new_account
          logger.info "Shibboleth: first access for this user, rendering the association page"
          render :associate
        else
          logger.info "Shibboleth: flag `shib_always_new_account` is set"
          logger.info "Shibboleth: first access for this user, automatically creating a new account"
          associate_with_new_account(@shib)
        end
      end
    end
  end

  # Associates the current shib user with an existing user or
  # a new user account (created here as well).
  def create_association

    # The federated user has no account yet, create one based on the info returned by
    # shibboleth
    if params[:new_account]
      associate_with_new_account(@shib)

    # Associate the shib user with an existing user account
    elsif params[:existent_account]
      associate_with_existent_account(@shib)

    # invalid request
    else
      flash[:notice] = t('shibboleth.create_association.invalid_parameters')
      redirect_to shibboleth_path
    end
  end

  def info
    if user_signed_in? && current_user.shib_token
      @data = current_user.shib_token.data
    end
    render :layout => false
  end

  private

  def load_shib_session
    logger.info "Shibboleth: creating a new Mconf::Shibboleth object"
    @shib = Mconf::Shibboleth.new(session)
    @shib.load_data(request.env, current_site.shib_env_variables)
  end

  # Checks if shibboleth is enabled in the current site.
  def check_shib_enabled
    unless current_site.shib_enabled
      logger.info "Shibboleth: tried to access but shibboleth is disabled"
      redirect_to login_path
      false
    else
      true
    end
  end

  # If there's a current user redirects to home.
  def check_current_user
    if user_signed_in?
      redirect_to after_sign_in_path_for(current_user)
      false
    else
      true
    end
  end

  # Renders a 404 if the flag `shib_always_new_account` is enabled.
  def check_shib_always_new_account
    if get_always_new_account()
      raise ActionController::RoutingError.new('Not Found')
    else
      true
    end
  end

  # When the user selected to create a new account for his shibboleth login.
  # Returns true if the user was created and associated successfully.
  def associate_with_new_account(shib)
    token = shib.find_or_create_token()

    # if there's already a user and an association, we don't need to do anything, just
    # return and, when the user is redirected back to #login, the token will be checked again
    if token.user.nil?
      token.user = shib.create_user(token)
      token.new_account = true # account created by shibboleth, not by the user
      user = token.user

      if user && user.errors.empty?
        logger.info "Shibboleth: created a new account: #{user.inspect}"
        token.data = shib.get_data
        token.save!
        shib.create_notification(token.user, token)
        flash[:success] = t('shibboleth.create_association.account_created', url: new_user_password_path).html_safe
        redirect_to shibboleth_path

      # error creating the user/token
      else
        logger.error "Shibboleth: error saving the new user created: #{user.errors.full_messages}"
        if User.where(email: user.email).count > 0
          logger.error "Shibboleth: there's already a user with this email #{shib.get_email}"
          flash[:error] = t('shibboleth.create_association.existent_account', email: shib.get_email)
        else
          message = t('shibboleth.create_association.error_saving_user', errors: user.errors.full_messages.join(', '))
          logger.error "Shibboleth: #{message}"
          flash[:error] = message
        end
        token.destroy
        redirect_to :back
      end

    # already has a token
    else
      redirect_to shibboleth_path
    end
  end

  # When the user selected to associate his shibboleth login with an account that already
  # exists.
  def associate_with_existent_account(shib)

    # try to authenticate the user with his login and password
    valid = false
    if params.has_key?(:user)
      # rejects anything but login and password to prevent errors
      password = params[:user][:password]
      params[:user].reject!{ |k, v| k.to_sym != :login }
      user = User.find_first_by_auth_conditions(params[:user])
      valid = user.valid_password?(password) unless user.nil?
    end

    # the user doesn't exist or the authentication was invalid (wrong username/password)
    if user.nil? or !valid
      logger.info "Shibboleth: invalid user or password #{user.inspect}"
      flash[:error] = t("shibboleth.create_association.invalid_credentials")

    # got the user and authenticated, but the user is disabled, can't let him be used
    elsif user.disabled
      logger.info "Shibboleth: attempt to associate with a disabled user #{user.inspect}"
      # don't need to tell the user the account is disabled, pretend it doesn't exist
      flash[:error] = t("shibboleth.create_association.invalid_credentials")

    # got the user and authenticated, everything ok
    else
      logger.info "Shibboleth: shib user associated to a valid user #{user.inspect}"

      # If there's a previous shibolleth token associated with this account, delete it
      user.shib_token.destroy if user.shib_token.present? # TODO: yet another failure point

      token = shib.find_or_create_token()
      token.user = user
      token.data = shib.get_data()
      token.save!

      # If the user comes from shibboleth and is not confirmed we can trust him
      if !user.confirmed?
        user.skip_confirmation!
        user.save!
      end

      flash[:success] = t("shibboleth.create_association.account_associated", :email => user.email)
    end

    redirect_to shibboleth_path
  end

  # Returns the value of the flag `shib_always_new_account`.
  def get_always_new_account
    return current_site.shib_always_new_account
  end

  # Checks if the user has an active enrollment, otherwise he's not allowed
  # to access the service. Will always allow superuser to sign in, even if they don't have
  # an active enrollment.
  # Note: assumes there is an enrollment field in the session, this verification should
  # be done before calling this.
  def check_active_enrollment(token=nil)
    is_superuser = token.present? && token.user_with_disabled.present? && token.user_with_disabled.superuser?
    data = request.env["ufrgsVinculo"]

    # "ativo" is at the beggining of line or after a ';'
    if data.match(/(^|;)ativo/) || is_superuser
      true
    else
      logger.error "Shibboleth: user doesn't have an active enrollment in the federation, " +
        "searched in #{data}"
      flash[:error] = t("shibboleth.create_association.enrollment_error")
      redirect_to request.referer || root_path
      false
    end
  end

  # Adds fake test data to the environment to test shibboleth in development.
  def test_data
    if Rails.env == "development"
      request.env["Shib-Application-ID"] = "default"
      request.env["Shib-Session-ID"] = "_412345e04a9fba98calks98d7c500852"
      request.env["Shib-Identity-Provider"] = "https://idp.mconf-institution.org/idp/shibboleth"
      request.env["Shib-Authentication-Instant"] = "2014-10-23T17:26:43.683Z"
      request.env["Shib-Authentication-Method"] = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
      request.env["Shib-AuthnContext-Class"] = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
      request.env["Shib-Session-Index"] = "alskd87345cc761850086ccbc4987123lskdic56a3c652c37fc7c3bdbos9dia87"
      request.env["Shib-eduPerson-eduPersonPrincipalName"] = "maria.leticia.da.silva@mconf-institution.org"
      request.env["Shib-inetOrgPerson-cn"] = "Maria Let\xC3\xADcia da Silva"
      request.env["Shib-inetOrgPerson-mail"] = "maria.leticia.da.silva@personal-email.org"
      request.env["Shib-inetOrgPerson-sn"] = "Let\xC3\xADcia da Silva"
      request.env["inetOrgPerson-cn"] = request.env["Shib-inetOrgPerson-cn"].clone
      request.env["inetOrgPerson-mail"] = request.env["Shib-inetOrgPerson-mail"].clone
      request.env["inetOrgPerson-sn"] = request.env["Shib-inetOrgPerson-sn"].clone
      request.env["cn"] = "Rick Astley"
      request.env["mail"] = "nevergonnagiveyouup@rick.com"
      request.env["uid"] = "00000000000"
      request.env["ufrgsVinculo"] = "ativo:7:Aluno de doutorado:NULL:NULL:NULL:NULL:1:EDUCAÇÃO:01/08/2012:NULL;inativo:15:Aluno especial de pós-graduação (Especial e Pós-doutorado):706:Programa de Pós-Graduação em Computação:NULL:NULL:NULL:Aluno Especial NA PÓS-GRADUAÇÃO:01/03/1999:30/07/1999;inativo:15:Aluno especial de pós-graduação (Especial e Pós-doutorado):1223:Programa de Pós-Graduação em Informática na Educação:NULL:NULL:NULL:Aluno Especial NA PÓS-GRADUAÇÃO:07/08/2007:31/12/2007;ativo:2:Docente:7421:Coordenação Acadêmica da SEAD:655:Colégio de Aplicação:NULL:NULL:05/07/1996:NULL;inativo:15:Aluno especial de pós-graduação (Especial e Pós-doutorado):706:Programa de Pós-Graduação em Computação:NULL:NULL:NULL:Aluno Especial NA PÓS-GRADUAÇÃO:01/08/1998:30/12/1998;inativo:15:Aluno especial de pós-graduação (Especial e Pós-doutorado):706:Programa de Pós-Graduação em Computação:NULL:NULL:NULL:Aluno Especial NA PÓS-GRADUAÇÃO:01/08/1997:30/12/1997;inativo:15:Aluno especial de pós-graduação (Especial e Pós-doutorado):1223:Programa de Pós-Graduação em Informática na Educação:NULL:NULL:NULL:Aluno Especial NA PÓS-GRADUAÇÃO:04/08/2008:09/12/2008;inativo:15:Aluno especial de pós-graduação (Especial e Pós-doutorado):706:Programa de Pós-Graduação em Computação:NULL:NULL:NULL:Aluno Especial NA PÓS-GRADUAÇÃO:01/03/1998:30/07/1998;inativo:15:Aluno especial de pós-graduação (Especial e Pós-doutorado):1223:Programa de Pós-Graduação em Informática na Educação:NULL:NULL:NULL:Aluno Especial NA PÓS-GRADUAÇÃO:10/03/2008:01/08/2008;inativo:6:Aluno de mestrado acadêmico:NULL:NULL:NULL:NULL:61:EDUCAÇÃO:01/03/2003:17/11/2008;inativo:15:Aluno especial de pós-graduação (Especial e Pós-doutorado):653:Programa de Pós-Graduação em Educação:NULL:NULL:NULL:Aluno Especial NA PÓS-GRADUAÇÃO:05/08/2002:16/12/2002"
      # request.env["ufrgsVinculo"] = "ativo:12:Funcionário de Fundações da UFRGS:1:Instituto de Informática:NULL:NULL:NULL:NULL:01/01/2011:NULL;inativo:6:Aluno de mestrado acadêmico:NULL:NULL:NULL:NULL:2:COMPUTAÇÃO:01/01/2001:11/12/2002"
    end
  end
end
