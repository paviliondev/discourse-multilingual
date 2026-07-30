import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { getOwner } from "@ember/owner";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { service } from "@ember/service";
import { bind } from "discourse/lib/decorators";
import UppyUpload from "discourse/lib/uppy/uppy-upload";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import dLoadingSpinner from "discourse/ui-kit/helpers/d-loading-spinner";
import { i18n } from "discourse-i18n";

export default class MultilingualUploader extends Component {
  @service messageBus;

  @tracked message;

  uppyUpload = new UppyUpload(getOwner(this), {
    id: this.args.id,
    type: "yml",
    preventDirectS3Uploads: true,
    uploadUrl: `/admin/multilingual/${this.args.uploadType}s`,
    validateUploadedFilesOptions: { skipValidation: true },
    uploadDone: () => {
      // wait for message that uploaded file is processed.
    },
  });

  constructor() {
    super(...arguments);
    this.messageBus.subscribe(
      "/uploads/" + this.uppyUpload.config.type,
      this.handleMessage
    );
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.messageBus.unsubscribe(
      "/uploads/" + this.uppyUpload.config.type,
      this.handleMessage
    );
  }

  get addDisabled() {
    return this.uppyUpload.uploading;
  }

  @bind
  handleMessage(msg) {
    if (msg.uploaded) {
      this.message = i18n("uploaded");
      this.done();
    } else if (msg.errors) {
      this.message = msg.errors[0];
    }

    setTimeout(() => {
      this.message = null;
    }, 10000);
  }

  <template>
    <div
      id="multilingual-uploader"
      class="multilingual-uploader {{@uploadType}}"
    >
      {{#if this.message}}
        <span>{{this.message}}</span>
      {{/if}}

      {{#if this.uppyUpload.uploading}}
        {{dLoadingSpinner size="small"}}
        <span>{{i18n "uploading"}}</span>
      {{/if}}

      <label class="btn btn-default {{if this.addDisabled 'disabled'}}">
        {{dIcon "upload"}}
        {{i18n "upload"}}
        <input
          {{didInsert this.uppyUpload.setup}}
          class="hidden-upload-field"
          disabled={{this.addDisabled}}
          type="file"
          accept="text/x-yaml"
        />
      </label>
    </div>
  </template>
}
