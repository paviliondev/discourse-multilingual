class Multilingual::AdminLanguagesController < Admin::AdminController
  def index
    serialize_languages(Multilingual::Language.query(query_params))
  end
  
  def update
    languages = JSON.parse(params[:languages])
    Multilingual::Language.update(languages)
    serialize_languages(Multilingual::Language.all)
  end
  
  def update_tags
    Jobs.enqueue(:update_language_tags)
    render json: success_json
  end
  
  def upload
    file = params[:file] || params[:files].first

    Scheduler::Defer.later("Upload languages") do
      begin
        languages = YAML.safe_load(file.tempfile)
        languages.each do |k, v|
          Multilingual::Language.create(k, v)
        end
        Multilingual::Language.refresh_associated_models
        data = { url: '/ok' }
      rescue => e
        data = failed_json.merge(errors: [e.message])
      end
      MessageBus.publish("/uploads/yml", data.as_json, client_ids: [params[:client_id]])
    end

    render json: success_json
  end
  
  protected
  
  def query_params
    params.permit(:filter, :order, :ascending)
  end
  
  def serialize_languages(languages)
    serializer = ActiveModel::ArraySerializer.new(languages, 
      each_serializer: Multilingual::AdminLanguageSerializer
    )
    render json: MultiJson.dump(serializer)
  end
end