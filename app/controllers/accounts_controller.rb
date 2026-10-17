class AccountsController < ApplicationController
  def show
    @user = Current.user
  end

  def update
    @user = Users::ChangePasswordService.call(session: Current.session, attributes: password_params)

    if @user.errors.none?
      redirect_to account_path, notice: t(".success")
    else
      render :show, status: :unprocessable_content
    end
  end

  private
    # A missing challenge would skip has_secure_password's current password check.
    def password_params
      params.expect(user: %i[ password_challenge password password_confirmation ]).with_defaults(password_challenge: "")
    end
end
