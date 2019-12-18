class Multilingual::AdminLanguagesController < Admin::AdminController
  def index
    serialize_languages(Multilingual::Language.filter(filter_params.to_h))
  end
  
  def remove
    if Multilingual::Admin.remove_all(params[:codes])
      serialize_languages(Multilingual::Language.filter(filter_params.to_h))
    else
      render json: failed_json
    end
  end
  
  def update
    if Multilingual::Admin.update_all(JSON.parse(params[:languages]))
      serialize_languages(Multilingual::Language.filter(filter_params.to_h))
    else
      render json: failed_json
    end
  end
  
  def upload
    file = params[:file] || params[:files].first
    
    Scheduler::Defer.later("Upload languages") do
      begin
        languages = YAML.safe_load(file.tempfile)
        Multilingual::Admin.add_all(languages)
        
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
    params.permit(:filter, :order, :ascending)
  end
  
  def serialize_languages(languages)
    Multilingual::Admin.refresh!
    serializer = ActiveModel::ArraySerializer.new(languages, 
      each_serializer: Multilingual::AdminLanguageSerializer
    )
    render json: MultiJson.dump(serializer)
  end
end