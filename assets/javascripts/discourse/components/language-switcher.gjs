/* eslint-disable discourse/i18n-import-location, discourse/moved-packages-import-paths, simple-import-sort/imports */
import i18n from "discourse-common/helpers/i18n";
import DMenu from "float-kit/components/d-menu";
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
