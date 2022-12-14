/**
* QCondition is used to build WHERE for SOQL statements
* @author  Jean-Philippe Monette
* @since   2017-03-21
*/
public class QCondition {

	public enum ComparisonOperator { EQUALS, NOT_EQUALS, LESS_THAN, LESS_OR_EQUAL, GREATER_THAN, GREATER_OR_EQUAL, IS_LIKE, IS_IN, NOT_IN, INCLUDES, EXCLUDES }

	private ComparisonOperator operatorValue;

	private String field {
		private get { return String.escapeSingleQuotes(field); }
		private set;
	}

	private Object fieldValue {
		private get { return formatFieldValue(fieldValue); }
		private set { fieldValue = value; }
	}
	public QCondition(String field) {
		this.field = field;
	}

	private Object formatFieldValue(Object val) {
		if (val instanceof List<Object>) {
			if (((List<Object>)val).isEmpty()) {
				return '\'\'';
			}

			List<String> values = new List<String>();
			for (Object value : (List<Object>) val) {
				if (value instanceof String) {
					values.add('\'' + String.escapeSingleQuotes((String) value) + '\'');
				} else if (value == null){
					values.add('\'' + '\'');
				} else {
					values.add((String) value);
				}
			}
			return String.join(values, ', ');
		}
		if (val instanceof String) {
			return '\'' + String.escapeSingleQuotes((String) val) + '\'';
		} else if (val instanceof Date) {
			String dateString = String.valueOf(val);
			return dateString.substring(0, dateString.indexOf(' '));
		} else if (val instanceof DateTime) {
            Datetime dt = (DateTime) val;
            return dt.formatGmt('yyyy-MM-dd') + 'T' + 
                   dt.formatGmt('HH:mm:ss')   + '.' + 
                   dt.formatGmt('SZ');
        } else if (val instanceof Q){
            return ((Q) val).build();
        } else {
			return val;
		}
	}

	public QCondition equalsTo(Object value) {
		this.operatorValue = ComparisonOperator.EQUALS;
		this.fieldValue = value;
		return this;
	}

	public QCondition notEqualsTo(Object value) {
		this.operatorValue = ComparisonOperator.NOT_EQUALS;
		this.fieldValue = value;
		return this;
	}

	public QCondition isLessThan(Object value) {
		this.operatorValue = ComparisonOperator.LESS_THAN;
		this.fieldValue = value;
		return this;
	}

	public QCondition isLessOrEquals(Object value) {
		this.operatorValue = ComparisonOperator.LESS_OR_EQUAL;
		this.fieldValue = value;
		return this;
	}

	public QCondition isGreaterThan(Object value) {
		this.operatorValue = ComparisonOperator.GREATER_THAN;
		this.fieldValue = value;
		return this;
	}

	public QCondition isGreaterOrEquals(Object value) {
		this.operatorValue = ComparisonOperator.GREATER_OR_EQUAL;
		this.fieldValue = value;
		return this;
	}

	public QCondition isLike(String value) {
		this.operatorValue = ComparisonOperator.IS_LIKE;
		this.fieldValue = value;
		return this;
	}

	public QCondition isIn(List<Object> values) {
		this.operatorValue = ComparisonOperator.IS_IN;
		this.fieldValue = values;
		return this;
	}

    public QCondition isIn(Q joinQuery) {
        this.operatorValue = ComparisonOperator.IS_IN;
        this.fieldValue = joinQuery;
        return this;
    }

	public QCondition isNotIn(List<Object> values) {
		this.operatorValue = ComparisonOperator.NOT_IN;
		this.fieldValue = values;
		return this;
	}

	public QCondition includes(List<Object> values) {
		this.operatorValue = ComparisonOperator.INCLUDES;
		this.fieldValue = values;
		return this;
	}

	public QCondition excludes(List<Object> values) {
		this.operatorValue = ComparisonOperator.EXCLUDES;
		this.fieldValue = values;
		return this;
	}

	public QCondition isNull() {
		this.operatorValue = ComparisonOperator.EQUALS;
		this.fieldValue = null;
		return this;
	}

	public QCondition isNotNull() {
		this.operatorValue = ComparisonOperator.NOT_EQUALS;
		this.fieldValue = null;
		return this;
	}

	public String build() {
		if (operatorValue.equals(ComparisonOperator.EQUALS)) {
			return field + ' = ' + fieldValue;
		} else if (operatorValue.equals(ComparisonOperator.NOT_EQUALS)) {
			return field + ' != ' + fieldValue;
		} else if (operatorValue.equals(ComparisonOperator.LESS_THAN)) {
			return field + ' < ' + fieldValue;
		} else if (operatorValue.equals(ComparisonOperator.LESS_OR_EQUAL)) {
			return field + ' <= ' + fieldValue;
		} else if (operatorValue.equals(ComparisonOperator.GREATER_THAN)) {
			return field + ' > ' + fieldValue;
		} else if (operatorValue.equals(ComparisonOperator.GREATER_OR_EQUAL)) {
			return field + ' >= ' + fieldValue;
		} else if (operatorValue.equals(ComparisonOperator.IS_LIKE)) {
			return field + ' LIKE ' + fieldValue;
		} else if (operatorValue.equals(ComparisonOperator.IS_IN)) {
			return field + ' IN (' + fieldValue + ')';
		} else if (operatorValue.equals(ComparisonOperator.NOT_IN)) {
			return field + ' NOT IN (' + fieldValue + ')';
		} else if (operatorValue.equals(ComparisonOperator.INCLUDES)) {
			return field + ' INCLUDES (' + fieldValue + ')';
		} else if (operatorValue.equals(ComparisonOperator.EXCLUDES)) {
			return field + ' EXCLUDES (' + fieldValue + ')';
		} else {
			return '';
		}
	}

}