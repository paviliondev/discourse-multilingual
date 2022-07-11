# frozen_string_literal: true
class Multilingual::AdminLanguagesController < Admin::AdminController
  def list
    serialize_languages(Multilingual::Language.filter(filter_params.to_h))
  end

  def remove
    opts = remove_params

    if Multilingual::CustomLanguage.bulk_destroy(opts[:locales])
      serialize_languages(Multilingual::Language.filter(filter_params.to_h))
    else
      render json: failed_json
    end
  end

  def update
    languages = language_params[:languages].map { |l| l.to_h }
    if Multilingual::Language.bulk_update(languages)
      serialize_languages(Multilingual::Language.filter(filter_params.to_h))
    else
      render json: failed_json
    end
  end

  def upload
    file = params[:file] || params[:files].first

    unless file && file.respond_to?(:tempfile)
      raise Discourse::InvalidParameters.new(:file)
    end

    Scheduler::Defer.later("Upload languages") do
      begin
        languages = YAML.safe_load(file.tempfile)

        Multilingual::CustomLanguage.bulk_create(languages)

        data = { uploaded: true }
      rescue => e
        data = failed_json.merge(errors: [e.message])
      end

      if params[:client_id]
        MessageBus.publish("/uploads/yml",
          data.as_json,
          client_ids: [params[:client_id]]
        )
      end
    end

    render json: success_json
  end

  protected

  def filter_params
    params.permit(:query, :order, :ascending)
  end

  def remove_params
    params.permit(locales: [])
  end

  def language_params
    params.permit(
      languages: [
        :locale,
        :name,
        :nativeName,
        :custom,
        :content_enabled,
        :interface_enabled,
        :interface_supported
      ]
    )
  end

  def serialize_languages(languages)
    render json: MultiJson.dump(ActiveModel::ArraySerializer.new(languages,
      each_serializer: Multilingual::LanguageSerializer
    ))
  end
end
