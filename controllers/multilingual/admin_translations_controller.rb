class Multilingual::AdminTranslationsController < Admin::AdminController
  def index
    serializer = ActiveModel::ArraySerializer.new(
      Multilingual::TranslationFile.all, 
      each_serializer: Multilingual::TranslationFileSerializer
    )
    render json: MultiJson.dump(serializer)
  end

  def upload
    file = params[:file] || params[:files].first
    
    Scheduler::Defer.later("Upload translation file") do
      data = {}
      
      begin
        yml = YAML.safe_load(file.tempfile)
        
        opts = process_filename(file.filename)
        raise opts[:error] if opts[:error]
        
        translation_file = Multilingual::TranslationFile.new(opts)
        
        result = translation_file.save(yml)
        raise result[:error] if result[:error]
        
        data = {
          uploaded: true,
          code: opts[:code],
          type: opts[:type]
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
    file = Multilingual::TranslationFile.new(translation_params)
    file.remove
    
    render json: {
      removed: true,
      code: file[:code],
      type: file[:type]
    }
  end
  
  def download
    translation_file = Multilingual::TranslationFile.new(translation_params)
    
    send_file(
      translation.path,
      filename: translation.filename,
      type: "yml"
    )
  end
  
  protected
  
  def translation_params
    params.permit(:code, :type)
  end
end