package data;

import global.Constants;
import global.StringUtils;

public class Queries {

    public static String insertPoolInto(String dbName) {
        return "INSERT INTO " + dbName + " (" +
              StringUtils.join(Constants.POOL_STRING_FIELD_NAMES.toArray(new String[0]), ", ")
              + ") VALUES (" + StringUtils.join(
              StringUtils.createArrayWithEqualStrings("?", Constants.POOL_STRING_FIELD_NAMES.size()),
              ", "
        ) + ");";
    }

    public static String insertPoolMetadataInto(String dbName) {
        return "INSERT INTO " + dbName + " (" +
              StringUtils.join(Constants.POOL_METADATA_STRING_FIELD_NAMES.toArray(new String[0]), ", ")
              + ") VALUES (" + StringUtils.join(
              StringUtils.createArrayWithEqualStrings("?", Constants.POOL_METADATA_STRING_FIELD_NAMES.size()),
              ", "
        ) + ");";
    }

    public static String removeFrom(String dbName) {
        return "DELETE FROM " + dbName + " WHERE " + Constants.POOL_PRIMARY_ID_FIELD_NAME + " = ? ;";
    }

    public static String updatePool(String dbName) {
        return "UPDATE " + dbName +
              " SET " +
              StringUtils.join(Constants.POOL_STRING_FIELD_NAMES.toArray(new String[0]), " = ? , ")
              + " = ? WHERE " + Constants.POOL_PRIMARY_ID_FIELD_NAME + " = ? ;";
    }

    public static String selectPoolsInRange(String dbName) {
        return "SELECT * FROM " + dbName +
              " WHERE " + Constants.POOL_PRIMARY_ID_FIELD_NAME +
              " >= ? AND " + Constants.POOL_PRIMARY_ID_FIELD_NAME + " < ? ;";
    }

    public static String selectCountNumberOfRows(String dbName) {
        return "SELECT COUNT(*) FROM " + dbName + ";";
    }

    public static String createPoolsTable(String dbName) {
        return "CREATE TABLE IF NOT EXISTS " + dbName + " (" +
              Constants.POOL_PRIMARY_ID_FIELD_NAME + " int primary key, " +
              StringUtils.join(Constants.POOL_STRING_FIELD_NAMES
                    .subList(1, Constants.POOL_STRING_FIELD_NAMES.size()).toArray(new String[0]), " text, ")
              + " text ) ;";
    }

    public static String createPoolsMetadataTable(String dbName) {
        return "CREATE TABLE IF NOT EXISTS " + dbName + " (" +
              Constants.POOL_PRIMARY_ID_FIELD_NAME + " int primary key, " +
              StringUtils.join(Constants.POOL_METADATA_STRING_FIELD_NAMES
                    .subList(1, Constants.POOL_METADATA_STRING_FIELD_NAMES.size()).toArray(new String[0]), " text, ")
              + " text ) ;";
    }

    public static String createTxCounterTable(String dbName) {
        return "CREATE TABLE IF NOT EXISTS " + dbName + " (" +
              "contract_address" + " text primary key, " +
              "count" + " int) ;";
    }

    public static String insertIntoTxCounter(String dbName) {
        return "INSERT INTO " + dbName + " (contract_address, count) VALUES (?, ?) ;";
    }

    public static String selectCounter(String dbName) {
        return "SELECT * FROM " + dbName + " WHERE contract_address = ?;";
    }

    public static String updateCounter(String dbName) {
        return "UPDATE " + dbName + " SET count = ? WHERE contract_address = ?;";
    }
}
