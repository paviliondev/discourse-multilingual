import SelectKitRowComponent from "select-kit/components/select-kit/select-kit-row";
import { default as DiscourseURL, userPath } from "discourse/lib/url";
import { default as computed } from 'ember-addons/ember-computed-decorators';

export default SelectKitRowComponent.extend({
  classNameBindings: ['additionalClasses', 'isHighlighted'],
  
  _setSelectionState() {
    if (this.value === 'set_content_language') {
      this.setProperties({
        isHighlighted: this.get("highlighted.value") === this.value
      });
    }
  },
  
  @computed('value')
  additionalClasses(value) {
    return value === 'set_content_language' ? 'set-content-language' : '';
  },

  click() {
    if (this.get('value') === 'set_content_language') {
      DiscourseURL.routeTo(
        userPath(this.get("currentUser.username_lower") + "/preferences/interface")
      )
    }
  }
});
