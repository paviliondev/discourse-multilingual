import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { eq } from "discourse/truth-helpers";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import I18n from "discourse-i18n";
import { addParam, localeParam } from "../lib/multilingual-route";

export default class LanguageSwitcherMenu extends Component {
  @service site;

  get currentLocale() {
    return I18n.currentLocale();
  }

  @action
  change(locale) {
    addParam(localeParam, locale, { add_cookie: true, ctx: this });
  }

  <template>
    <div class="language-switcher-menu">
      <ul>
        {{#each this.site.interface_languages as |l|}}
          <li>
            {{! eslint-disable ember/template-no-invalid-interactive }}
            <a
              class={{dConcatClass
                "ls-language"
                (if (eq l.locale this.currentLocale) "current")
              }}
              {{on "click" (fn this.change l.locale)}}
              label={{l.name}}
            >
              {{l.name}}
            </a>
          </li>
        {{/each}}
      </ul>
    </div>
  </template>
}
