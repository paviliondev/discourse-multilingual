import MultiSelectComponent from "select-kit/components/multi-select";
import ContentLanguagesMixin from "../mixins/content-languages-mixin";

export default MultiSelectComponent.extend(ContentLanguagesMixin, {
  classNames: ['content-languages-selector', 'classNames'],
  rowComponent: "content-languages-row",
  allowAny: false,
  filterable: true
});