import { equal } from "@ember/object/computed";
import discourseComputed from "discourse-common/utils/decorators";

export default Ember.Component.extend({
  classNames: 'admin-language-list',
  showActions: equal('type', 'custom'),
  
  @discourseComputed('type')
  titleKey(type) {
    return `multilingual.languages.${type}`;
  }
})