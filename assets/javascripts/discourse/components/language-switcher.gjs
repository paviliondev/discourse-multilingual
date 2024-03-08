import Component from "@glimmer/component";
import DMenu from "float-kit/components/d-menu";
import i18n from "discourse-common/helpers/i18n";
import LanguageSwitcherMenu from "./language-switcher-menu";

export default class LanguageSwitcher extends Component {
  <template>
    <DMenu
      title={{i18n "user.locale.title"}}
      @icon="translate"
      id="multilingual-language-switcher"
      class="icon btn-flat"
    >
      <:content>
        <LanguageSwitcherMenu />
      </:content>
    </DMenu>
  </template>
}