import SelectKitRowComponent from "select-kit/components/select-kit/select-kit-row";
import { default as DiscourseURL, userPath } from "discourse/lib/url";
import { default as computed, on } from "discourse-common/utils/decorators";

const setKey = 'set_content_language';

export default SelectKitRowComponent.extend({
  classNameBindings: ['additionalClasses'],
  
  @on("didReceiveAttrs")
  _setSelectionState() {
    if (this.value === setKey) {
      this.set('isHighlighted', this.get("highlighted.value") === this.value);
    }
  },
  
  @computed('value')
  additionalClasses(value) {
    return value === setKey ? setKey.dasherize() : '';
  },
  
  @computed('value', 'name')
  label(value, name) {
    if (this.value === setKey) {
      return name;
    } else {
      return `${name} (${value})`;
    }
  },

  click() {
    if (this.get('value') === setKey) {
      DiscourseURL.routeTo(
        userPath(this.get("currentUser.username_lower") + "/preferences/interface")
      )
    } else {
      this._super();
    }
  }
});
