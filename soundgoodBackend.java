package soundgoodBackend;

import soundgoodBackend.databaseDriver.databaseDriver;

import java.sql.*;
import java.text.ParseException;
import java.text.SimpleDateFormat;

public class soundgoodBackend {
    private static final Integer MAX_RENTAL_ALLOWANCE = 2;

    public static void main(String[] args) {

        System.out.println("SoundGood Backend ultra alpha edition");
        String[] argsList = args[0].split(" ");
        try {
            switch (argsList[0]) {
                case "list":
                    if (argsList[1].isEmpty()) {
                        System.out.println("Invalid command: list <instrument>");
                        return;
                    }
                    list(argsList[1]);
                    break;
                case "rent":
                    if (argsList[1].isEmpty() || argsList[2].isEmpty() || argsList[3].isEmpty()) {
                        System.out.println("Invalid command: rent <studentID> <instrumentID> <endDate>");
                        return;
                    }
                    rent(argsList[1], argsList[2], argsList[3]);
                    break;
                case "terminate":
                    if (argsList[1].isEmpty() || argsList[2].isEmpty()) {
                        System.out.println("Invalid command: terminate <studentID> <instrumentID>");
                        return;
                    }
                    terminate(argsList[1], argsList[2]);
                    break;
                default:
                    System.out.println("Invalid command: [list | rent | terminate]");
            }
        } catch (SQLException e) {
            System.out.println("Database error: " + e.getMessage());
        }
    }

    private static void printRows(ResultSet rs) throws SQLException {
        // Iterate over column names and print them
        for (int i = 1; i <= rs.getMetaData().getColumnCount(); i++) {
            System.out.print(rs.getMetaData().getColumnName(i) + " | ");
        }
        System.out.println("\n---------------");

        // Iterate over rows and print them
        while (rs.next()) {
            for (int i = 1; i <= rs.getMetaData().getColumnCount(); i++) {
                System.out.print(rs.getString(i) + "\t");
            }
            System.out.print("\n");
        }
    }

    private static void list(String instrumentName) throws SQLException {
        System.out.println("Listing available " + instrumentName + "s:\n");

        Connection connection = databaseDriver.get().getConnection();
        try (PreparedStatement ps = connection.prepareStatement("" +
                "SELECT price, brand " +
                "FROM RENTAL_INSTRUMENTS " +
                "LEFT JOIN RENTALS ON (RENTAL_INSTRUMENTS.ID = RENTALS.INSTRUMENT_ID) " +
                "WHERE (END_DATE IS NULL OR END_DATE < CURRENT_DATE) AND name = ?;")) {
            ps.setString(1, instrumentName);
            ResultSet rs = ps.executeQuery();
            printRows(rs);
            rs.close();
        }
    }

    private static void rent(String studentID, String instrumentID, String endDate) throws SQLException {
        System.out.println("Renting instrument: " + instrumentID + " for student: " + studentID + " until: " + endDate);
        Connection connection = databaseDriver.get().getConnection();

        // Check to see if user has exceeded maximum number of rental instruments
        try (PreparedStatement ps = connection.prepareStatement("SELECT get_active_rental_count(?);")) {
            ps.setInt(1, Integer.parseInt(studentID));
            ResultSet rs = ps.executeQuery();
            while (rs.next()) { // Should only be one row, but we need the cursor in position
                if (rs.getInt(1) >= MAX_RENTAL_ALLOWANCE) {
                    throw new RuntimeException("Student already has 2 active rentals.");
                }
            }
            rs.close();
        }

        // Add the rental to the database
        try (PreparedStatement ps = connection.prepareStatement("" +
                "INSERT INTO rentals (person_id, start_date, end_date, instrument_id) " +
                "VALUES (?, CURRENT_DATE, ?, ?);")) {
            ps.setInt(1, Integer.parseInt(studentID));
            try {
                SimpleDateFormat dateFormatter = new SimpleDateFormat("yyyy-MM-dd");
                ps.setDate(2, new java.sql.Date(dateFormatter.parse(endDate).getTime()));
            } catch (ParseException e) {
                throw new RuntimeException("Invalid date format: " + endDate);
            }

            ps.setInt(3, Integer.parseInt(instrumentID));
            ps.executeUpdate();
        }
    }

    private static void terminate(String personID, String instrumentID) throws SQLException {
        System.out.println("Terminating rental for: " + personID + " of instrument: " + instrumentID);
        Connection connection = databaseDriver.get().getConnection();

        try (PreparedStatement ps = connection.prepareStatement("UPDATE rentals SET end_date = CURRENT_DATE WHERE person_id = ? AND instrument_id = ?;")) {
            ps.setInt(1, Integer.parseInt(personID));
            ps.setInt(2, Integer.parseInt(instrumentID));
            ps.executeUpdate();
        }
    }
}
