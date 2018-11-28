module I18n
  class ForceMissingTranslationsHandler < ExceptionHandler
    def call(exception, locale, key, options)
      if Rails.env.test? or Rails.env.development?
        raise exception.to_exception
      else
        super
      end
    end
  end
end

I18n.exception_handler = I18n::ForceMissingTranslationsHandler.new
