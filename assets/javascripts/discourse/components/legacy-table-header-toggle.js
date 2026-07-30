/* eslint-disable ember/no-classic-components, ember/require-tagless-components */

import Component from "@ember/component";
import { computed } from "@ember/object";
import { schedule } from "@ember/runloop";
import { trustHTML } from "@ember/template";
import {
  attributeBindings,
  classNames,
  tagName,
} from "@ember-decorators/component";
import { iconHTML } from "discourse/lib/icon-library";
import { i18n } from "discourse-i18n";

@tagName("th")
@classNames("sortable")
@attributeBindings("title", "colspan", "ariaSort:aria-sort", "role")
export default class LegacyTableHeaderToggle extends Component {
  role = "columnheader";
  labelKey = null;
  chevronIcon = null;
  columnIcon = null;
  translated = false;
  automatic = false;
  onActiveRender = null;
  pressedState = null;
  ariaLabel = null;

  @computed("order", "field", "asc")
  get ariaSort() {
    if (this.order === this.field) {
      return this.asc ? "ascending" : "descending";
    } else {
      return "none";
    }
  }

  toggleProperties() {
    if (this.order === this.field) {
      this.set("asc", this.asc ? null : true);
    } else {
      this.setProperties({ order: this.field, asc: null });
    }
  }

  toggleChevron() {
    if (this.order === this.field) {
      const chevron = iconHTML(this.asc ? "chevron-up" : "chevron-down");
      this.set("chevronIcon", trustHTML(`${chevron}`));
    } else {
      this.set("chevronIcon", null);
    }
  }

  click() {
    this.toggleProperties();
  }

  keyPress(e) {
    if (e.which === 13) {
      this.toggleProperties();
    }
  }

  didReceiveAttrs() {
    super.didReceiveAttrs(...arguments);
    if (!this.automatic && !this.translated) {
      this.set("labelKey", this.field);
    }
    this.set("id", `table-header-toggle-${this.field.replace(/\s/g, "")}`);
    this.toggleChevron();
    this._updateA11yAttributes();
  }

  didRender() {
    super.didRender(...arguments);
    if (this.onActiveRender && this.chevronIcon) {
      this.onActiveRender(this.element);
    }
  }

  _updateA11yAttributes() {
    let criteria = "";
    const pressed = this.order === this.field;

    if (this.icon === "heart") {
      criteria += `${i18n("likes_lowercase", { count: 2 })} `;
    }

    if (this.translated) {
      criteria += this.field;
    } else {
      const labelKey = this.labelKey || `directory.${this.field}`;

      criteria += i18n(labelKey + "_long", {
        defaultValue: i18n(labelKey),
      });
    }

    this.set("ariaLabel", i18n("directory.sort.label", { criteria }));

    if (pressed) {
      if (this.asc) {
        this.set("pressedState", "mixed");
      } else {
        this.set("pressedState", "true");
      }

      this._focusHeader();
    } else {
      this.set("pressedState", "false");
    }
  }

  _focusHeader() {
    schedule("afterRender", () => {
      document.getElementById(this.id)?.focus();
    });
  }
}
