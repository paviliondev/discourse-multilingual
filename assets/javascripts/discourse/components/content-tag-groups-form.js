import { action } from "@ember/object";
import { service } from "@ember/service";
import TagGroupsForm from "discourse/components/tag-groups-form";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

export default class ContentTagGroupsForm extends TagGroupsForm {
  @service dialog;

  _updateContentTags() {
    this.set(
      "changingContentTags",
      i18n("tagging.groups.content_tags.update.message")
    );

    ajax(`/tag_groups/${this.model.id}/content-tags`, {
      type: "PUT",
    })
      .catch(popupAjaxError)
      .then(() => this.set("changingContentTags", null))
      .finally(() => this.tagsChanged());
  }

  _destroyContentTags() {
    this.set(
      "changingContentTags",
      i18n("tagging.groups.content_tags.delete.message")
    );

    ajax(`/tag_groups/${this.model.id}/content-tags`, {
      type: "DELETE",
    })
      .catch(popupAjaxError)
      .then(() => this.set("changingContentTags", null))
      .finally(() => this.tagsChanged());
  }

  @action
  destroyContentTags() {
    this.dialog.deleteConfirm({
      title: i18n("tagging.groups.content_tags.delete.confirm"),
      didConfirm: () => this._destroyContentTags(),
    });
  }

  @action
  updateContentTags() {
    this._updateContentTags();
  }
}
