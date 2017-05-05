debug = require('debug')('security:acl')

module.exports = ->

  @factory 'resolvePermission', (AccessContext, AccessPrincipal, getMatchingScore) ->
    (acls, context) ->
      req = new AccessRequest context

      acls = acls.sort (rule1, rule2) ->
        getMatchingScore(rule2, req) - getMatchingScore(rule1, req)

      permission = AccessContext.DEFAULT

      score = 0
      i = 0

      while i < acls.length
        candidate = acls[i]

        if not acls[i].score
          acls[i].score = getMatchingScore(candidate, req)

        score = acls[i].score

        if score < 0
          # the highest scored ACL did not match
          break

        if !req.isWildcard()
          # We should stop from the first match for non-wildcard
          permission = candidate.permission
          break
        else
          if req.exactlyMatches(candidate)
            permission = candidate.permission
            break

          # For wildcard match, find the strongest permission
          candidateOrder = AccessContext.permissionOrder[candidate.permission]
          permissionOrder = AccessContext.permissionOrder[permission]

          if candidateOrder > permissionOrder
            permission = candidate.permission

        i++

      if debug.enabled
        debug 'The following ACLs were searched: '

        acls.forEach (acl) ->
          acl.debug()

      req.permission = permission

      req
