# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

module FeatureFlags
  module Hooks
    def self.final_grades_override_custom_transition_hook(_user, context, from_state, transitions)
      transitions["off"] ||= {}
      transitions["on"] ||= {}

      # This is a "one-way" flag:
      #  - Once Allowed, it can no longer be set to Off.
      #  - Once On, it can no longer be Off nor Allowed.
      case context
      when Course
        transitions["off"]["locked"] = true if from_state == "on" # lock off to enforce no take backs
      when Account
        transitions["allowed"] ||= {}
        case from_state
        when "allowed"
          transitions["off"]["locked"] = true # lock off to enforce no take backs
        when "on"
          # lock both `off` and `allowed` to enforce no take backs
          transitions["off"]["locked"] = true
          transitions["allowed"]["locked"] = true
        end
      end
    end

    def self.use_semi_colon_field_separators_in_gradebook_exports_custom_transition_hook(_user, context, _from_state, transitions)
      if context.feature_enabled?(:autodetect_field_separators_for_gradebook_exports)
        transitions["on"] ||= {}
        transitions["on"]["locked"] = true
        transitions["on"]["warning"] = I18n.t("This feature can't be enabled while autodetection of field separators is enabled")
      end
    end

    def self.autodetect_field_separators_for_gradebook_exports_custom_transition_hook(_user, context, _from_state, transitions)
      if context.feature_enabled?(:use_semi_colon_field_separators_in_gradebook_exports)
        transitions["on"] ||= {}
        transitions["on"]["locked"] = true
        transitions["on"]["warning"] = I18n.t("This feature can't be enabled while semicolons are forced to be field separators")
      end
    end

    def self.quizzes_next_visible_on_hook(context)
      root_account = context.root_account
      # assume all Quizzes.Next provisions so far have been done through uuid_provisioner
      #  so all provisioned accounts will have the FF in Canvas UI
      root_account.settings&.dig(:provision, "lti").present?
    end

    def self.docviewer_enable_iwork_visible_on_hook(context)
      root_account = context.root_account

      # Right now Apple only has a server in the US, to comply with GDPR, we'll only turn this on for folks in the US.
      root_account.external_integration_keys.find_by(key_type: "salesforce_billing_country_code")&.key_value == "US"
    end

    def self.usage_metrics_allowed_hook(context)
      UsageMetricsPredicate.new(context, Shard.current.database_server.config[:region]).call
    end

    def self.analytics_2_after_state_change_hook(_user, context, _old_state, _new_state)
      # if we clear the nav cache before HAStore clears, it can be recached with stale FF data
      nav_cache = Lti::NavigationCache.new(context.root_account)
      nav_cache.delay_if_production(run_at: 1.minute.from_now).invalidate_cache_key
      nav_cache.delay_if_production(run_at: 5.minutes.from_now).invalidate_cache_key
    end

    def self.k6_theme_hook(_user, _context, _from_state, transitions)
      transitions["on"] ||= {}
      transitions["on"]["message"] =
        I18n.t("Enabling the Elementary Theme will change the font in the Canvas interface and simplify "\
               "the Course Navigation Menu for all users in your course.")
      transitions["on"]["reload_page"] = true
      transitions["off"] ||= {}
      transitions["off"]["message"] =
        I18n.t("Disabling the Elementary Theme will change the font in the Canvas interface for all users in your course.")
      transitions["off"]["reload_page"] = true
    end

    def self.mastery_scales_after_change_hook(_user, context, _old_state, new_state)
      if context.is_a?(Account) && OutcomesService::Service.enabled_in_context?(context)
        OutcomesService::Service.delay_if_production(priority: Delayed::LOW_PRIORITY,
                                                     n_strand: [
                                                       "outcomes_service_toggle_context_proficiencies_feature_flag",
                                                       context.global_root_account_id
                                                     ])
                                .toggle_feature_flag(
                                  context.root_account,
                                  "context_proficiencies",
                                  new_state == "on"
                                )
      end
    end
  end
end
