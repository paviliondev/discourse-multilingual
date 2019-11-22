import SelectKitRowComponent from "select-kit/components/select-kit/select-kit-row";
import {default as DiscourseURL, userPath } from "discourse/lib/url";
import { default as computed } from 'ember-addons/ember-computed-decorators';

export default SelectKitRowComponent.extend({
  classNameBindings: ['additionalClasses', 'isHighlighted'],
  
  @computed('value')
  additionalClasses(value) {
    return value === 'set_content_language' ? 'set-content-language' : '';
  },
  
  @computed('value', 'name')
  label(value, name) {
    if (this.value === 'set_content_language') {
      return name;
    } else {
      return `${name} (${value})`;
    }
  },

  click() {
    if (this.get('value') === 'set_content_language') {
      DiscourseURL.routeTo(
        userPath(this.get("currentUser.username_lower") + "/preferences/interface")
      )
    } else {
      this._super();
    }
  }
});
