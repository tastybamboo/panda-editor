# frozen_string_literal: true

module Panda
  module Editor
    class PdfUrlsController < ActionController::Base
      protect_from_forgery with: :exception

      def show
        blob = ActiveStorage::Blob.find_signed!(params[:signed_id])

        unless blob.content_type == "application/pdf"
          head :unprocessable_entity
          return
        end

        render json: {url: blob.url(disposition: :inline, expires_in: 5.minutes)}
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        head :not_found
      end
    end
  end
end
