import Component from '@glimmer/component';
import { inject as service } from "@ember/service";
// import { on } from "@ember/object/evented";
// import { scheduleOnce } from "@ember/runloop";

export default class ContentLanguage extends Component {
  @service siteSettings;

  get shouldRender() {
    return (
      this.siteSettings.multilingual_enabled &&
      this.siteSettings.multilingual_content_languages_enabled &&
      this.siteSettings.multilingual_content_languages_topic_filtering_enabled
    );
  }

  //TODO work out if this is still necessary
  // @on("init")
  // setup() {
  //   scheduleOnce("afterRender", () => {
  //     const content = ".control-group.content-languages";
  //     const int = ".control-group.pref-locale";
  //     const text = ".control-group.text-size";
  //     const form = ".user-preferences form";

  //     if ($(text).length && !$(form).children(content).length) {
  //       $(content).prependTo(form);
  //     }

  //     if (!$(content).next(int).length) {
  //       $(int).insertAfter(content);
  //     }
  //   });
  // },
};
