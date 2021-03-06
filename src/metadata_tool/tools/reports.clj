;
; Copyright 2017 Fintech Open Source Foundation
; SPDX-License-Identifier: Apache-2.0
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;     http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
;
(ns metadata-tool.tools.reports
  (:require [clojure.string                 :as str]
            [clojure.tools.logging          :as log]
            [clj-http.client                :as http]
            [mount.core                     :as mnt :refer [defstate]]
            [clj-time.core                  :as tm]
            [clj-time.format                :as tf]
            [postal.core                    :as email]
            [metadata-tool.config           :as cfg]
            [metadata-tool.template         :as tem]
            [metadata-tool.sources.github   :as gh]
            [metadata-tool.sources.metadata :as md]
            [metadata-tool.sources.bitergia :as bi]))

(def ^:private inactive-project-threshold-days
  "The threshold (days) at which a project is considered 'inactive'"
  180)

(def ^:private old-pr-threshold-days
  "The threshold (days) at which a PR is considered 'old'"
  60)

(def ^:private old-issue-threshold-days
  "The threshold (days) at which an issue is considered 'old'"
  90)

(defstate email-config
  :start (:email cfg/config))

(defstate email-user
  :start (:user email-config))

(defstate email-override
  :start (:email-override cfg/config))

(defstate test-email-address
  :start (:test-email-address email-config))

(def ^:private program-liaison-email-address "program-liaison@finos.org")

(defn- send-email
  "Sends a UTF8 HTML email to the given to-addresses (which can be either a string or a vector of strings)."
  [to-addresses subject body & {:keys [cc-addresses from-address reply-to-address]
                                :or {from-address      email-user
                                     reply-to-address  email-user}}]
  (let [[to-addresses cc-addresses from-address reply-to-address]
        (if email-override
          [to-addresses       cc-addresses from-address       reply-to-address]      ; Only use the passed in values if the --email-override switch has been provided
          [test-email-address nil          test-email-address test-email-address])]  ; Otherwise use the test email address throughout
    (log/info "Sending email to" to-addresses "with subject:" subject)
    (email/send-message email-config
                        {:from     from-address
                         :reply-to reply-to-address
                         :to       to-addresses
                         :cc       cc-addresses
                         :subject  subject
                         :body     [{:type    "text/html; charset=\"UTF-8\""
                                     :content body}]})))

(defn- activity-stale?
  [activity stale-date]
  (let [activity-date (tf/parse (tf/formatters :date) (:contribution-date activity))
        compare-date (compare stale-date activity-date)]
    (and (pos? compare-date) (= "INCUBATING" (:state activity)))))

(defn- send-email-to-pmc
  [program-id subject body]
  ; TODO - enable code below and comment out print commands!
  ; (println "===========================")
  ; (println subject)
  ; (println "---------------------------")
  ; (println body)
  ; (println "==========================="))
  (if-not (str/blank? program-id)
    (send-email (:pmc-mailing-list-address (md/program-metadata program-id))
                subject
                body
                :cc-addresses     program-liaison-email-address
                :reply-to-address program-liaison-email-address)))

(defn participation-img
  [type program]
  (let [short-name (:program-short-name program)
        img-url    (str
                    "https://raw.githubusercontent.com/finos/reports-job/master/active-participation-reports/"
                    (str/lower-case short-name)
                    "-"
                    type
                    ".png")]
    (try
      (http/get img-url)
      img-url
      (catch Exception e
        (println (str "Warn - URL '" img-url "' returns 404"))))))

(defn email-pmc-reports
  []
  (let [now-str                                          (tf/unparse (tf/formatter "yyyy-MM-dd h:mmaa ZZZ") (tm/now))
        all-programs                                     (md/programs-metadata)
        six-months-ago                                   (tm/minus (tm/now) (tm/months 6))
        ; to build local report based on last 12 months of activity
        ; six-months-ago                                   (tm/minus (tm/now) (tm/months 12))
        
        unarchived-activities-without-leads              (group-by :program-id
                                                                   (remove #(= "ARCHIVED" (:state %))
                                                                           (filter #(str/blank? (:lead-or-chair-person-id %))
                                                                                   (md/activities-metadata))))
        inactive-unarchived-activities-metadata          (group-by :program-id
                                                                   (remove #(= "ARCHIVED" (:state %))
                                                                           (keep md/activity-metadata-by-name
                                                                                 (bi/inactive-projects inactive-project-threshold-days))))
        stale-incubating-activities-metadata             (group-by :program-id
                                                                   (filter #(activity-stale? % six-months-ago)
                                                                           (md/activities-metadata)))
        unarchived-activities-with-unactioned-prs        (group-by :program-id
                                                                   (remove #(= "ARCHIVED" (:state %))
                                                                           (keep md/activity-metadata-by-name
                                                                                 (bi/projects-with-old-prs old-pr-threshold-days))))
        unarchived-activities-with-unactioned-issues     (group-by :program-id
                                                                   (remove #(= "ARCHIVED" (:state %))
                                                                           (keep md/activity-metadata-by-name
                                                                                 (bi/projects-with-old-issues old-issue-threshold-days))))
        unarchived-activities-with-non-standard-licenses (group-by :program-id
                                                                   (filter #(some identity (map (fn [gh-url]
                                                                                                  (let [gh-repo-license (str/lower-case (str (:spdx_id (:license (gh/repo gh-url)))))]  ; Note underscore in :spdx_id!
                                                                                                    (and (not= gh-repo-license "apache-2.0")
                                                                                                         (not= gh-repo-license "cc-by-4.0"))))
                                                                                                (:github-urls %)))
                                                                           (remove #(= "ARCHIVED" (:state %)) (md/activities-metadata))))
        archived-activities-that-arent-github-archived   (group-by :program-id
                                                                   (remove #(some identity
                                                                                  (map (fn [gh-url] (:archived (gh/repo gh-url)))
                                                                                       (:github-urls %)))
                                                                           (filter #(and (= "ARCHIVED" (:state %))
                                                                                         (pos? (count (:github-urls %))))
                                                                                   (md/activities-metadata))))
        activities-with-repos-without-issues-support     (group-by :program-id
                                                                   (filter #(some identity (map (fn [gh-url] (not (:has_issues (gh/repo gh-url))))  ; Note underscore in :has_issues!
                                                                                                (:github-urls %)))
                                                                           (md/activities-metadata)))]
    (doall (map #(send-email-to-pmc (:program-id %)
                                    (str (:program-short-name %) " PMC Report as at " now-str)
                                    (tem/render "emails/pmc-report.ftl"
                                                {:now                                              now-str
                                                 :inactive-days                                    inactive-project-threshold-days
                                                 :old-pr-threshold-days                            old-pr-threshold-days
                                                 :old-issue-threshold-days                         old-issue-threshold-days
                                                 :program                                          %
                                                 :wg-participation-img                             (participation-img "working_group" %)
                                                 :project-participation-img                        (participation-img "project" %)
                                                 :working-groups                                   (md/activities % "WORKING_GROUP")
                                                 :projects                                         (md/activities % "PROJECT")
                                                 :pmc-lead                                         (md/pmc-lead %)
                                                 :orgs-in-pmc                                      (md/orgs-in-pmc %)
                                                 :pmc-list                                         (md/pmc-list %)
                                                 :unarchived-activities-without-leads              (seq (sort-by :activity-name (get unarchived-activities-without-leads              (:program-id %))))
                                                 :inactive-activities                              (seq (sort-by :activity-name (get inactive-unarchived-activities-metadata          (:program-id %))))
                                                 :stale-activities                                 (seq (sort-by :activity-name (get stale-incubating-activities-metadata             (:program-id %))))
                                                 :activities-with-unactioned-prs                   (seq (sort-by :activity-name (get unarchived-activities-with-unactioned-prs        (:program-id %))))
                                                 :activities-with-unactioned-issues                (seq (sort-by :activity-name (get unarchived-activities-with-unactioned-issues     (:program-id %))))
                                                 :unarchived-activities-with-non-standard-licenses (seq (sort-by :activity-name (get unarchived-activities-with-non-standard-licenses (:program-id %))))
                                                 :archived-activities-that-arent-github-archived   (seq (sort-by :activity-name (get archived-activities-that-arent-github-archived   (:program-id %))))
                                                 :activities-with-repos-without-issues-support     (seq (sort-by :activity-name (get activities-with-repos-without-issues-support     (:program-id %))))}))
                all-programs))))
