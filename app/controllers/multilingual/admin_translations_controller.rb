# frozen_string_literal: true
class Multilingual::AdminTranslationsController < Admin::AdminController
  def list
    serializer = ActiveModel::ArraySerializer.new(
      Multilingual::TranslationFile.all,
      each_serializer: Multilingual::TranslationFileSerializer
    )
    render json: MultiJson.dump(serializer)
  end

  def upload
    raw_file = params[:file] || params[:files].first

    unless raw_file && raw_file.respond_to?(:tempfile)
      raise Discourse::InvalidParameters.new(:file)
    end

    Scheduler::Defer.later("Upload translation file") do
      data = {}
      tempfile =

      begin
        yml = YAML.safe_load(raw_file.tempfile)

        opts = Multilingual::TranslationFile.process_filename(raw_file.original_filename)
        raise opts[:error] if opts[:error]

        file = Multilingual::TranslationFile.new(opts)

        result = file.save(yml)
        raise result[:error] if result[:error]

        data = {
          uploaded: true,
          code: file.code,
          type: file.type
        }
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

  def remove
    opts = translation_params
    file = Multilingual::TranslationFile.new(opts)
    file.remove

    render json: {
      removed: true,
      code: opts[:code],
      type: opts[:type]
    }
  end

  def download
    file = Multilingual::TranslationFile.new(translation_params)

    send_file(
      file.path,
      filename: file.filename,
      type: "yml"
    )
  end

  protected

  def translation_params
    params.permit(:code, :type)
  end
end
