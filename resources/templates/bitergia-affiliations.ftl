[#ftl]
# ⚠️ BITERGIA FOLKS: DO NOT EDIT THIS FILE!! ⚠️ 
# We generate this file from a separate data source, and your changes WILL BE OVERWRITTEN AND LOST!
# If you need to make changes, please create an issue and we'll add your changes to the source data set.

[#list people as person]
- profile:
    name: ${person.full_name}
  [#if person.is_bot??]
    is_bot: ${person.is_bot?c}
  [/#if]
  [#if person.affiliations?? && person.affiliations?size > 0]
  enrollments:
    [#list person.affiliations as affiliation]
    - organization: ${affiliation.organization.organization_name}
      [#if affiliation.start_date??]
      start: ${affiliation.start_date}
      [/#if]
      [#if affiliation.end_date??]
      end: ${affiliation.end_date}
      [/#if]
    [/#list]
  [/#if]
  [#if person.github_logins?? && person.github_logins?size > 0]
  github:
    [#list person.github_logins as github_login]
    - ${github_login}
    [/#list]
  [/#if]
  [#if person.confluence_usernames?? && person.confluence_usernames?size > 0]
  confluence:
    [#list person.confluence_usernames as confluence_username]
    - ${confluence_username}
    [/#list]
  [/#if]
  [#if person.email_addresses?? && person.email_addresses?size > 0]
  email:
    [#list person.email_addresses as email_address]
    - ${email_address}
    [/#list]
  [/#if]

[/#list]
