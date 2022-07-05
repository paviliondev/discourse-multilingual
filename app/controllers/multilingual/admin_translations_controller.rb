# frozen_string_literal: true
class Multilingual::AdminTranslationsController < Admin::AdminController
  def list
    serializer = ActiveModel::ArraySerializer.new(
      Multilingual::CustomTranslation.all,
      each_serializer: Multilingual::CustomTranslationSerializer
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

        file = raw_file.original_filename

        opts = process_filename(file)
          raise opts[:error] if opts[:error]

        locale, file_type, ext = opts.values_at(:locale, :file_type, :ext)

        result = Multilingual::CustomTranslation.create!(file_name: file, locale: locale, file_type: file_type, file_ext: ext, translation_data: yml)

        data = {
          uploaded: true,
          locale: result.locale,
          file_type: result.file_type
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

    file = Multilingual::CustomTranslation.where(file_type: opts[:file_type], locale: opts[:locale]).first
    file.remove

    render json: {
      removed: true,
      locale: opts[:locale],
      type: opts[:file_type]
    }
  end

  def download
    file = Multilingual::CustomTranslation.new(translation_params)

    send_file(
      file.path,
      filename: file.filename,
      type: "yml"
    )
  end

  protected

  def translation_params
    params.permit(:locale, :file_type)
  end

  def process_filename(filename)
    result = Hash.new

    #TODO improve this with more standard/robust filename manipulation?
    parts = filename.split('.')
    result = {
      file_type: parts[0],
      locale: parts[1],
      ext: parts[2]
    }

    if !Multilingual::Translation.validate_type(result[:file_type])
      result[:error] = 'invalid type'
    end

    if result[:ext] != 'yml'
      result[:error] = "incorrect format"
    end

    result
  end
end
