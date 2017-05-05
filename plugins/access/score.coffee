module.exports = ->

  @factory 'getMatchingScore', (AccessContext, AccessPrincipal, injector) ->
    (rule, req) ->
      props = [
        'model'
        'property'
        'accessType'
      ]

      score = 0
      i = 0

      while i < props.length
        # Shift the score by 4 for each of the properties as the weight
        if rule[props[i]]
          score = score * 4

          ruleValue = rule[props[i]]
          requestedValue = req[props[i]]

          if props[i] is 'accessType'
            ruleValue = ruleValue or AccessContext.ALL
            #requestedValue = requestedValue or AccessContext.ALL

          isMatchingMethodName = props[i] == 'property' and req.methodNames.indexOf(ruleValue) != -1
          isMatchingAccessType = ruleValue == requestedValue

          if props[i] == 'accessType' and !isMatchingAccessType
            switch ruleValue
              when AccessContext.EXECUTE, AccessContext.READ, AccessContext.WRITE, AccessContext.REPLICATE
                # EXECUTE should match READ, REPLICATE and WRITE
                isMatchingAccessType = true
              when AccessContext.WRITE
                # WRITE should match REPLICATE too
                isMatchingAccessType = requestedValue == AccessContext.REPLICATE

          if isMatchingMethodName or isMatchingAccessType
            # Exact match
            score += 3
          else if ruleValue == AccessContext.ALL
            # Wildcard match
            score += 2
          else if requestedValue == AccessContext.ALL
            score += 1

        i++

      # Weigh against the principal type into 4 levels
      # - user level (explicitly allow/deny a given user)
      # - app level (explicitly allow/deny a given app)
      # - role level (role based authorization)
      # - other
      # user > app > role > ...
      if rule.principalType
        score = score * 4

        switch rule.principalType
          when AccessPrincipal.USER
            score += 4
          when AccessPrincipal.APP
            score += 3
          when AccessPrincipal.ROLE
            score += 2
          else
            score += 1

      # Weigh against the roles
      # everyone < authenticated/unauthenticated < related < owner < ...
      if rule.principalType == AccessPrincipal.ROLE
        score = score * 8

        ACL = injector.get 'ACL'

        switch rule.principalId
          when ACL.OWNER
            score += 4
          when ACL.RELATED
            score += 3
          when ACL.AUTHENTICATED, ACL.UNAUTHENTICATED
            score += 2
          when ACL.EVERYONE
            score += 1
          else
            score += 5

      score = score * 4
      score += AccessContext.permissionOrder[rule.permission or AccessContext.ALLOW] - 1

      score
