import ComboBox from "select-kit/components/combo-box";
import ContentLanguagesMixin from "../mixins/content-languages-mixin";

export default ComboBox.extend(ContentLanguagesMixin, {
  classNames: ['content-languages-selector', 'classNames'],
  allowAny: false,
  allowCreate: false,
  filterable: true
});