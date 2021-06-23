module Response
  def get_value_and_flash_now(response, default: nil)
    case response.status
    when :success, :fail
      value = response.body
      respond_with_flash_now(response) unless response.message.nil?
    when :error
      respond_with_flash_now(response)
      value = default
    end
    value
  end

  def get_value(response, default: nil)
    case response.status
    when :success, :fail
      value = response.body
    when :error
      value = default
    end
    value
  end

  def respond_with_flash(response, redirect_path)
    case response.status
    when :success
      respond_to do |format|
        flash.notice = response.message unless response.message.nil?
        format.html { redirect_to redirect_path }
      end
    when :error
      respond_to do |format|
        flash.alert = response.message
        format.html { redirect_to redirect_path }
      end
    end
  end

  def respond_with_flash_now(response)
    case response.status
    when :success
      flash.now[:notice] = response.message unless response.message.nil?
    when :error, :fail
      flash.now[:alert] = response.message
    end
  end
end
