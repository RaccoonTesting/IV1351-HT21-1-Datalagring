package soundgoodBackend.databaseDriver;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

public class databaseDriver {
    static final String connString = "jdbc:postgresql://localhost:5432/soundgood_music_school";
    static final String dbUser = "postgres";
    static final String dbPassword = "Let'sdothis1";
    private Connection conn = null;
    private static databaseDriver instance = null;

    private databaseDriver() throws SQLException {
        Properties connectionProps = new Properties();
        connectionProps.setProperty("user", dbUser);
        connectionProps.setProperty("password", dbPassword);
        conn = DriverManager.getConnection(connString, connectionProps);
    }


    public static databaseDriver get() throws SQLException {
        if (instance == null) {
            instance = new databaseDriver();
        }
        return instance;
    }

    public Connection getConnection() {
        return conn;
    }

}
