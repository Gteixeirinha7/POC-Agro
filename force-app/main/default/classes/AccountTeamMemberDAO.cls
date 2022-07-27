public with sharing class AccountTeamMemberDAO {
   
    public static List<AccountTeamMember> getAccountTeamMemberByAccountId(List<String> accountIds, Set<String> accountTeamMemberUsedFields) {

        String query = new Q(AccountTeamMember.SObjectType)
            .selectFields(accountTeamMemberUsedFields)
            .add(Q.condition('AccountId').isIn(accountIds))
            .build();
            
        return Database.query(query);
    }
}
