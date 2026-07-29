import DiscourseRecommended from "@discourse/lint-configs/eslint";

export default [
  ...DiscourseRecommended,
  {
    rules: {
      "simple-import-sort/imports": "off",
      "ember/no-classic-components": "off",
      "discourse/discourse-common-imports": "off",
      "ember/no-classic-classes": "off",
      "ember/require-tagless-components": "off",
      "ember/avoid-leaking-state-in-ember-objects": "off",
      "ember/no-actions-hash": "off",
      "discourse/i18n-import-location": "off",
      "ember/no-jquery": "off",
      "discourse/ui-kit-imports": "off",
      "discourse/truth-helpers-imports": "off",
      "discourse/moved-packages-import-paths": "off",
      "ember/template-no-template-lint-directives": "off",
      "ember/template-no-invalid-interactive": "off",
      "discourse/deprecated-imports": "off",
      "ember/no-observers": "off",
      "discourse/plugin-api-no-version": "off",
      "qunit/no-loose-assertions": "off",
      "qunit/no-assert-equal": "off",
    },
  },
];
