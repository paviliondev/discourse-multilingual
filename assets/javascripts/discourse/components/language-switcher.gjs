import DMenu from "discourse/float-kit/components/d-menu";
import { i18n } from "discourse-i18n";
import LanguageSwitcherMenu from "./language-switcher-menu";

export default <template>
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
