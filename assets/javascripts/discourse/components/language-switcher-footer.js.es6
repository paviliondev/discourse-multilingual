import Component from '@glimmer/component';
import { inject as service } from "@ember/service";

export default class LanguageSwitcherFooter extends Component {
  @service siteSettings;
  @service currentUser;

 shouldRender() {
    return (
      this.siteSettings.multilingual_enabled &&
      this.siteSettings.multilingual_guest_language_switcher === "footer" &&
      !this.siteSettings.login_required &&
      !this.currentUser
    );
  }
};
