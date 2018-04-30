[#ftl output_format="HTML"]
[#macro activity_table_head]
      <thead>
        <tr>
          <th>Activity</th>
          <th>Type</th>
          <th><a href="https://finosfoundation.atlassian.net/wiki/spaces/FINOS/pages/75530756/Project+and+Working+Group+Lifecycles">Lifecycle State</a></th>
          <th>GitHub Repositories</th>
          <th>Project Lead/Working Group Chair</th>
        </tr>
      </thead>
[/#macro]
[#macro render_type type]
  [#if type = "PROJECT"]Project[#elseif type = "WORKING_GROUP"]Working Group[/#if]
[/#macro]
[#macro render_state state]
  [#switch state]
    [#case "INCUBATING"]<a href="https://finosfoundation.atlassian.net/wiki/spaces/FINOS/pages/75530363/Incubating">Incubating</a>[#break]
    [#case "RELEASED"]<a href="https://finosfoundation.atlassian.net/wiki/spaces/FINOS/pages/75530371/Released">Released</a>[#break]
    [#case "OPERATING"]<a href="https://finosfoundation.atlassian.net/wiki/spaces/FINOS/pages/93061261/Operating">Operating</a>[#break]
    [#case "PAUSED"]<a href="https://finosfoundation.atlassian.net/wiki/spaces/FINOS/pages/93290700/Paused">Paused</a>[#break]
    [#case "ARCHIVED"]<a href="https://finosfoundation.atlassian.net/wiki/spaces/FINOS/pages/75530367/Archived">Archived</a>[#break]
  [/#switch]
[/#macro]
[#macro render_activity_row activity]
        <tr>
          <td>${activity.activity_name}</td>
          <td>[@render_type activity.type /]</td>
          <td>[@render_state activity.state /]</td>
          <td>[#if activity.github_urls?? && activity.github_urls?size > 0][#list activity.github_urls as github_url]
            <a style="font-family: courier, monospace;" href="${github_url}">${github_url?keep_after("github.com/")}</a>[#if github_url != activity.github_urls?last]<br/>[/#if]
          [/#list][#else]
            This [@render_type activity.type /] has no GitHub repositories.
          [/#if]</td>
          <td>[#if activity.lead_or_chair??]
            [#local has_email_address = activity.lead_or_chair.email_addresses?? &&
                                        activity.lead_or_chair.email_addresses?size > 0 &&
                                        !activity.lead_or_chair.email_addresses?first?ends_with("@users.noreply.github.com")]
            [#if has_email_address]<a href="mailto:${activity.lead_or_chair.email_addresses?first}">[/#if]
              ${activity.lead_or_chair.full_name}
            [#if has_email_address]</a>[/#if]
          [#else]
            [#if activity.type = "PROJECT"]⚠️ This project has no lead.[#elseif activity.type = "WORKING_GROUP"]⚠️ This working group has no chair.[/#if]
          [/#if]</td>
        </tr>
[/#macro]
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <style>
  body {
    font-family: Montserrat, san-serif;
    font-weight: 500;
  }
  table, th, td {
    border: 1px solid #acacac;
    border-collapse: collapse;
  }
  th, td {
    padding: 2px;
  }
  th {
    background-color: #acacac;
  }
  </style>
</head>
<body>
  <h3>${program.program_short_name} PMC Report as at ${now}</h3>
  <p>Please see <a href="https://finosfoundation.atlassian.net/wiki/spaces/FINOS/pages/118292491/Automated+Reports">the wiki</a>
     for more information on this report, including recommended remedies.  The
     <a href="https://metrics.finos.org/app/kibana?#/dashboard/C_ESCo_projects?_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-2y,mode:quick,to:now))&_a=(filters:!(),query:(query_string:(analyze_wildcard:!t,query:'cm_program:%22${program.program_short_name}%22')))"/>${program.program_short_name} Program's metrics dashboard</a>
     also provides more insight into the activity of the Program's Projects and Working Groups.</p>
  <hr/>
[#if (inactive_activities?? && inactive_activities?size > 0) ||
     (activities_with_unactioned_prs?? && activities_with_unactioned_prs?size > 0) ||
     (activities_with_unactioned_issues?? && activities_with_unactioned_issues?size > 0) ||
     (archived_activities_that_arent_github_archived?? && archived_activities_that_arent_github_archived?size > 0) ||
     (activities_with_repos_without_issues_support?? && activities_with_repos_without_issues_support?size > 0)]
  [#if inactive_activities?? && inactive_activities?size > 0]
  <p><b>Inactive Activities</b></p>
  <p>Here are inactive Projects and Working Groups, defined as being those
     with no git commit or GitHub issue/PR activity in the last ${inactive_days}
     days, that are not in
     <a href="https://finosfoundation.atlassian.net/wiki/spaces/FINOS/pages/75530367/Archived">Archived state</a>:</p>
  <blockquote>
    <table width="100%" border=1 cellspacing=0 cellpadding=1>
[@activity_table_head /]
      <tbody>
    [#list inactive_activities as activity]
[@render_activity_row activity /]
    [/#list]
      </tbody>
      </table>
  </blockquote>
  <hr/>
  [/#if]
  [#if activities_with_unactioned_prs?? && activities_with_unactioned_prs?size > 0]
  <p><b>Activities with Unactioned PRs</b></p>
  <p>Here are the Projects and Working Groups that have unactioned PRs, defined as being those
     with PRs with more than ${old_pr_threshold_days} days of inactivity, that are not in
     <a href="https://finosfoundation.atlassian.net/wiki/spaces/FINOS/pages/75530367/Archived">Archived state</a>:</p>
  <blockquote>
    <table width="100%" border=1 cellspacing=0>
[@activity_table_head /]
      <tbody>
    [#list activities_with_unactioned_prs as activity]
[@render_activity_row activity /]
    [/#list]
      </tbody>
    </table>
  </blockquote>
  <hr/>
  [/#if]
  [#if activities_with_unactioned_issues?? && activities_with_unactioned_issues?size > 0]
  <p><b>Activities with Unactioned Issues</b></p>
  <p>Here are the Projects and Working Groups that have unactioned issues, defined as being those
     with issues with more than ${old_issue_threshold_days} days of inactivity, that are not in
     <a href="https://finosfoundation.atlassian.net/wiki/spaces/FINOS/pages/75530367/Archived">Archived state</a>:</p>
  <blockquote>
    <table width="100%" border=1 cellspacing=0>
[@activity_table_head /]
      <tbody>
    [#list activities_with_unactioned_issues as activity]
[@render_activity_row activity /]
    [/#list]
      </tbody>
    </table>
  </blockquote>
  <hr/>
  [/#if]
  [#if archived_activities_that_arent_github_archived?? && archived_activities_that_arent_github_archived?size > 0]
  <p><b>Archived Activities that Aren't Archived in GitHub</b></p>
  <p>Here are the <a href="https://finosfoundation.atlassian.net/wiki/spaces/FINOS/pages/75530367/Archived">Archived</a>
     Projects and Working Groups that have GitHub repositories that haven't been archived (set to read-only)
     in GitHub yet:</p>
  <blockquote>
    <table width="100%" border=1 cellspacing=0>
[@activity_table_head /]
      <tbody>
    [#list archived_activities_that_arent_github_archived as activity]
[@render_activity_row activity /]
    [/#list]
      </tbody>
    </table>
  </blockquote>
  <hr/>
  [/#if]
  [#if activities_with_repos_without_issues_support?? && activities_with_repos_without_issues_support?size > 0]
  <p><b>Activities that Have GitHub Repositories Without Issue Tracking Enabled</b></p>
  <p>Here are the Projects and Working Groups that have GitHub repositories that don't
     have issue tracking enabled:</p>
  <blockquote>
    <table width="100%" border=1 cellspacing=0>
[@activity_table_head /]
      <tbody>
    [#list activities_with_repos_without_issues_support as activity]
[@render_activity_row activity /]
    [/#list]
      </tbody>
    </table>
  </blockquote>
  <hr/>
  [/#if]
[#else]
  <p>All Projects and Working Groups seem to be operating smoothly.&nbsp;&nbsp;🎉</p>
  <hr/>
[/#if]
  <p style="font-size: small; text-align: center;">Need help? Raise a <a href="https://finosfoundation.atlassian.net/secure/CreateIssue.jspa?pid=10000&issuetype=10001">HELP issue</a>
    or send an email to <a href="mailto:help@finos.org">help@finos.org</a>.
    <br/>&nbsp;<br/>
    Copyright 2018 <b style="color:#0086bf">FINOS</b><br/>
    Content in this email is licensed under the <a href="https://creativecommons.org/licenses/by/4.0/">CC BY 4.0 license</a>.<br/>
    Code in this email is licensed under the <a href="https://www.apache.org/licenses/LICENSE-2.0">Apache 2.0 license</a>.</p>
</body>
</html>