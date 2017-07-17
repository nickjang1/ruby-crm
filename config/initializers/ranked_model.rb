# http://www.postgresql.org/docs/8.3/interactive/datatype-numeric.html#DATATYPE-NUMERIC-TABLE

silence_warnings do
  RankedModel::MIN_RANK_VALUE = 0
  RankedModel::MAX_RANK_VALUE = 2147483646
end
