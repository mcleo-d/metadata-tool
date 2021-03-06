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
(ns metadata-tool.tools.listers
  (:require [clojure.pprint                 :as pp]
            [metadata-tool.sources.schemas  :as sch]
            [metadata-tool.sources.metadata :as md]))

(defn list-schemas
  []
  (doall (map pp/pprint sch/schema-ids)))

(defn list-people-with-clas
  []
  (doall (map #(pp/pprint (:full-name %)) (sort-by :full-name (md/people-with-clas)))))


