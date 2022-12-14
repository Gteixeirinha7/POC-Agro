/**
* Q is used to build SOQL statements
* @author  Jean-Philippe Monette
* @since   2017-03-21
*/
public class Q {

	private String fromText;
	private Integer numberOfRows;
	private Integer numberOfRowsToSkip;
	private Boolean allRows = false; 

	private Set<String> fieldList = new Set<String>();
	private List<QOrder> orders = new List<QOrder>();
	private List<QCondition> conditions = new List<QCondition>();
	private List<QConditionGroup> conditionGroups = new List<QConditionGroup>();
	private List<Q> subQueries = new List<Q>();

	public Q(SObjectType fromType)	{ this.fromText = String.valueOf(fromType); }
	public Q(String fromText) 		{ this.fromText = fromText; }

	/**
	 * Instantiate an OrderBy object
	 */
	public static QOrder orderBy(String fieldName) {
		QOrder od = new QOrder(fieldName);
		return od;
	}

	/**
	 * Instantiate a Condition object
	 */
	public static QCondition condition(String fieldName) {
		QCondition cond = new QCondition(fieldName);
		return cond;
	}

	/**
	 * Instantiate a Condition Group object
	 */
	public static QConditionGroup conditionGroup(List<QCondition> conditions){
		QConditionGroup conditionGroups = new QConditionGroup(conditions);
		return conditionGroups;
	}

	/**
	 * Add an OrderBy statement
	 */
	public Q add(QOrder ob) {
		this.orders.add(ob);
		return this;
	}

	/**
	 * Add a Condition statement
	 */
	public Q add(QCondition cnd) {
		this.conditions.add(cnd);
		return this;
	}

	/**
	 * Add a Condition Group statement
	 */
	public Q add(QConditionGroup grp) {
		this.conditionGroups.add(grp);
		return this;
	}

	/**
	 * Add an SELECT sub-query
	 */
	public Q addSubquery(Q qb) {
		this.subQueries.add(qb);
		return this;
	}

	/**
	 * Add fields to the SELECT statement from FieldSet
	 */
	public Q selectFields(Schema.FieldSet fs) {
		for(Schema.FieldSetMember field : fs.getFields()) {
			this.fieldList.add(field.getFieldPath());
		}
		return this;
	}

	/**
	 * Add fields to the SELECT statement from Set of Strings
	 */
	public Q selectFields(Set<String> fields) {
		for(String field : fields) {
			this.fieldList.add(field);
		}
		return this;
	}

    /**
	 * Add COUNT() to the SELECT statement and remove any other declared fields
	 */
    public Q count() {
        this.fieldList.clear();
        this.fieldList.add('COUNT()');
        return this;
    }

	/**
	 * Add a ALL ROWS statement
	 */
	public Q addAllRows() {
		this.allRows = true;
		return this;
	}

	/**
	 * Add a LIMIT statement
	 */
	public Q addLimit(Integer i) {
		this.numberOfRows = i;
		return this;
	}

	/**
	 * Add an OFFSET statement
	 */
	public Q addOffset(Integer i) {
		this.numberOfRowsToSkip = i;
		return this;
	}

	/**
	 * Build the SELECT statement
	 */
	public String buildSelect() {
		for (Q qb : this.subQueries) {
			this.fieldList.add('(' + qb.build() + ')');
		}

		if (!this.fieldList.isEmpty()) {
			return 'SELECT ' + String.join(new List<String>(this.fieldList), ', ');
		} else {
			return 'SELECT Id';
		}
	}

	/**
	 * Build the WHERE statement
	 */
	public String buildConditions() {
		List<String> condList = new List<String>();

		for (QCondition cond : this.conditions) {
			condList.add(cond.build());
		}

		if (!this.conditions.isEmpty()) {
			return 'WHERE ' + String.join(condList, ' AND ');
		} else {
			return null;
		}
	}

	/**
	 * Build the WHERE statement based on the condition groups
	 */
	public String buildConditionGroups() {
		
		List<String> conditionsJoined = new List<String>();
		List<String> conditionClauses;
			
		for(QConditionGroup conditionGroups : this.conditionGroups){

			conditionClauses = new List<String>();

			System.debug('conditionGroups.conditions => ' + conditionGroups.conditions);

			for(QCondition condition : conditionGroups.conditions){

				System.debug('condition => ' + condition);

				conditionClauses.add(condition.build());

			}				
			
			System.debug('conditionsJoined => ' + conditionsJoined);
			System.debug('conditionGroups.logicalOperator => ' + conditionGroups.logicalOperator);

			conditionsJoined.add('(' + String.join(conditionClauses, conditionGroups.logicalOperator) + ')');

			System.debug('conditionsJoined => ' + conditionsJoined);
			
		}

		System.debug('conditionsJoined => ' + conditionsJoined);

		return ' WHERE ' + String.join(conditionsJoined, ' OR ');

	}

	/**
	 * Build the ORDER BY statement
	 */
	public String buildOrderBy() {
		List<String> orderList = new List<String>();

		for (QOrder order : this.orders) {
			orderList.add(order.build());
		}

		if (!this.orders.isEmpty()) {
			return 'ORDER BY ' + String.join(orderList, ', ');
		} else {
			return '';
		}

	}

	/**
	 * Build the SOQL query
	 */
	public String build() {
		List<String> queryParts = new List<String>();

		queryParts.add(this.buildSelect());
		queryParts.add('FROM ' + this.fromText);

		if (!this.conditions.isEmpty()) {
			queryParts.add(this.buildConditions());
		}

		if (!this.conditionGroups.isEmpty()) {
			queryParts.add(this.buildConditionGroups());
		}

		if (!this.orders.isEmpty()) {
			queryParts.add(this.buildOrderBy());
		}

		if (this.numberOfRows != null) {
			queryParts.add('LIMIT ' + this.numberOfRows);
		}

		if (this.numberOfRowsToSkip != null) {
			queryParts.add('OFFSET ' + this.numberOfRowsToSkip);
		}

		if (this.allRows){
			queryParts.add('ALL ROWS');
		}

		return String.join(queryParts, ' ');
	}

}