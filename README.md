# Discourse Multilingual Plugin
This Discourse plugin adds features useful in a multilingual Discourse.

![img](https://travis-ci.org/paviliondev/discourse-multilingual.svg?branch=master)

## Installation

Follow the directions at [Install a Plugin](https://meta.discourse.org/t/install-a-plugin/19157) using https://github.com/discourse/discourse-multilingual.git as the repository URL.

## Usage

### Site Settings

``multilingual_enabled`` disables both server-side and client-side code in the plugin if it's switched off. This is to make it easy to disable it if an issue occurs. It's off by default.

``multilingual_language_source_url`` should be set to the source of the language data. Currently it assumes the source is the in format stored in https://raw.githubusercontent.com/wikimedia/language-data/master/data/langdb.yaml.

### Importing data

Every 24 hours the plugin will automatically import language data stored at the ``multilingual_language_source_url``. The plugin does two things with that data:

1. Store all language ISO codes (e.g. ``en``) and the language names (e.g. ``English``) in the Discourse database (safely in the PluginStore).

2. Create tags in the tag group ``languages`` for all language codes (see yourforum.com/tag_groups).

### Content Languages

The content language feature set is designed to filter all content on the forum by a particular language.

### User Setting

When the plugin is enabled a user can set their content language(s) in their interface preferences (``/u/username/preferences/interface``). The options for that setting are all the imported languages. The user can choose more than one language.

#### Navigation

When the multilingual plugin is enabled there is a new dropdown added to the Discourse navigation. When a user has selected content languages in their settings, these will be listed in the dropdown. The last item of the dropdown is a link to the user's content language settings.

Also, the normal tag navigation input will not contain language tags.

#### Creating and Editing Topics

The plugin adds a "Languages" input in the new topic composer 

![18%20PM|690x156](upload://lbxcwUBa7XYTQZW4Yq6ptqJQtpO.png) 

and in the "edit topic" UI

![00%20AM|690x151](upload://5eiIlUutugzWSi3xtFe95Hikb93.png) 

These controls allow the user to tag a topic as being in a certain language(s). When a user has a content language set, the content language inputs default to the user's content languages.

Note that, even though the content language tags are "tags", they will not appear in the normal tag input in the composer or edit topic UI. You can only add and remove content language tags in the separate content languages input.

#### Topics and Topic Lists

When a user sets a content language(s), this is applied to the topic list generation logic on the server so that the user will only see topics tagged with their content language in topic lists on the forum.

Content language tags are also distinguished in the topic, and topic list item elements. Content language tags appear after the normal tag list, preceded by a multilingual icon (an svg adapted from the [Google Material Design translate icon](https://material.io/resources/icons/?icon=translate&style=baseline))

![44%20AM|602x138,50%](upload://gJuqiCAYGOLROyb0Pz6u4brTQSb.png) 

#### Tags

When you look at the list of the language tags in /tag_groups, you will notice that the tags are the ISO codes, e.g. ``en``. However, you will notice that in the forum itself the tags are displayed with the native language name, e.g. ``English``. Whenever language tags are displayed in the app they will be displayed with in their native language name.

The reason this approach is taken is that, to have functional tags, it is necessary to use a simple english string, i.e. the ISO codes. However most users will not be familiar with the ISO codes, particularly the less widely used ones. 

Note that the tag itself, is the ISO code. This means that when using Discourse's tag-specific features, such as route-based tag filtering, you need to use the ISO code.

## Authors

Angus McLeod

## License

GNU GPL v2
