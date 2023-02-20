import MultilingualTranslation from "../models/multilingual-translation";
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class AdminMultilingualTranslations extends Component {
  @tracked refreshing = false;
  @tracked translations = [];

  constructor() {
    super(...arguments);
    this._refresh();
  };

  _refresh() {
    this.refreshing = true;

    MultilingualTranslation.list()
      .then((result) => {
       this.translations = result;
      })
      .finally(() => {
        this.refreshing = false;
      });
  };

  @action
  refresh() {
    this._refresh();
  };
};
