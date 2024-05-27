# Advanced Reports in SQL Northwind

## Context

The `Northwind` database contains sales data for a company called `Northwind Traders`, which imports and exports specialty foods from around the world.

The Northwind database is an ERP system with data on customers, orders, inventory, purchases, suppliers, shipping, employees, and accounting.

The Northwind dataset includes sample data for the following:

* **Suppliers:** Northwind's suppliers and vendors
* **Customers:** Customers who purchase products from Northwind
* **Employees:** Details of Northwind Traders' employees
* **Products:** Product information
* **Shippers:** Details of the shippers that deliver the products from traders to end customers
* **Orders and Order Details:** Sales order transactions occurring between customers and the company

The `Northwind` database includes 14 tables, and the relationships between the tables are shown in the following entity-relationship diagram.

![northwind](https://github.com/lvgalvao/Northwind-SQL-Analytics/blob/main/pics/northwind-er-diagram.png?raw=true)

## Objective

This repository aims to present advanced reports built in SQL. The analyses provided here can be applied to companies of all sizes that wish to become more analytical. Through these reports, organizations will be able to extract valuable insights from their data, aiding in strategic decision-making.

## Initial Setup

### Manually

Use the provided SQL file, `northwind.sql`, to populate your database.

### With Docker and Docker Compose

**Prerequisite**: Install Docker and Docker Compose

* [Get started with Docker](https://www.docker.com/get-started)
* [Install Docker Compose](https://docs.docker.com/compose/install/)

### Steps for setup with Docker:

1. **Start Docker Compose** Run the following command to bring up the services:
    
    ```
    docker-compose up
    ```
    
    Wait for the setup messages, such as:
    
    ```csharp
    Creating network "northwind_psql_db" with driver "bridge"
    Creating volume "northwind_psql_db" with default driver
    Creating volume "northwind_psql_pgadmin" with default driver
    Creating pgadmin ... done
    Creating db      ... done
    ```
       
2. **Connect to PgAdmin** Access PgAdmin via the URL: [http://localhost:5050](http://localhost:5050), with the password `postgres`. 

Configure a new server in PgAdmin:
    
    * **General tab**:
        * Name: db
    * **Connection tab**:
        * Host name: db
        * Username: postgres
        * Password: postgres Then select the "northwind" database.

3. **Stop Docker Compose** Stop the server started by the `docker-compose up` command using Ctrl-C and remove the containers with:
    
    ```
    docker-compose down
    ```
    
4. **Files and Persistence** Your modifications to the Postgres databases will be persisted in the Docker volume `postgresql_data` and can be retrieved by restarting Docker Compose with `docker-compose up`. To delete the database data, run:
    
    ```
    docker-compose down -v
    ```

## Relatórios que vamos criar

1. **Revenue Report**
    
    * What was the total revenue in the year 1997?

    ```sql
    SELECT SUM((order_details.unit_price) * order_details.quantity * (1.0 - order_details.discount)) AS total_revenues_1997
    FROM order_details
    INNER JOIN (
        SELECT order_id 
        FROM orders 
        WHERE EXTRACT(YEAR FROM order_date) = '1997'
    ) AS ord 
    ON ord.order_id = order_details.order_id;
    ```

    * Monthly growth and YTD Revenue Analysis

    ```sql
    WITH MonthRevenue AS (
        SELECT
            EXTRACT(YEAR FROM orders.order_date) AS YEAR,
            EXTRACT(MONTH FROM orders.order_date) AS MONTH,
            SUM(order_details.unit_price * order_details.quantity * (1.0 - order_details.discount)) AS Month_Revenue
        FROM
            orders
        INNER JOIN
            order_details ON orders.order_id = order_details.order_id
        GROUP BY
            EXTRACT(YEAR FROM orders.order_date),
            EXTRACT(MONTH FROM orders.order_date)
    ),
    AcumulatedRevenue AS (
        SELECT
            YEAR,
            MONTH,
            Month_Revenue,
            SUM(Month_Revenue) OVER (PARTITION BY YEAR ORDER BY MONTH) AS Revenue_YTD
        FROM
            MonthRevenue
    )
    SELECT
        YEAR,
        MONTH,
        Month_Revenue,
        Month_Revenue - LAG(Month_Revenue) OVER (PARTITION BY YEAR ORDER BY MONTH) AS Month_Diference,
        Revenue_YTD,
        (Month_Revenue - LAG(Month_Revenue) OVER (PARTITION BY YEAR ORDER BY MONTH)) / LAG(month_Revenue) OVER (PARTITION BY YEAR ORDER BY MONTH) * 100 AS Month_Change_Percent
    FROM
        AcumulatedRevenue
    ORDER BY
        YEAR, MONTH;
    ```

2. **Customer Segmentation**
    
    * What is the total amount each customer has paid so far?

    ```sql
    SELECT 
        customers.company_name, 
        SUM(order_details.unit_price * order_details.quantity * (1.0 - order_details.discount)) AS total
    FROM 
        customers
    INNER JOIN 
        orders ON customers.customer_id = orders.customer_id
    INNER JOIN 
        order_details ON order_details.order_id = orders.order_id
    GROUP BY 
        customers.company_name
    ORDER BY 
        total DESC;
    ```

    * Segment the customers in 5 groups according to customer's revenue

    ```sql
    SELECT 
    customers.company_name, 
    SUM(order_details.unit_price * order_details.quantity * (1.0 - order_details.discount)) AS total,
    NTILE(5) OVER (ORDER BY SUM(order_details.unit_price * order_details.quantity * (1.0 - order_details.discount)) DESC) AS group_number
    FROM 
        customers
    INNER JOIN 
        orders ON customers.customer_id = orders.customer_id
    INNER JOIN 
        order_details ON order_details.order_id = orders.order_id
    GROUP BY 
        customers.company_name
    ORDER BY 
        total DESC;
    ```


    * Now only the customers who are in groups 3, 4, and 5, so that a special Marketing analysis can be done with them.

    ```sql
    WITH clients_to_marketing AS (
        SELECT 
        customers.company_name, 
        SUM(order_details.unit_price * order_details.quantity * (1.0 - order_details.discount)) AS total,
        NTILE(5) OVER (ORDER BY SUM(order_details.unit_price * order_details.quantity * (1.0 - order_details.discount)) DESC) AS group_number
    FROM 
        customers
    INNER JOIN 
        orders ON customers.customer_id = orders.customer_id
    INNER JOIN 
        order_details ON order_details.order_id = orders.order_id
    GROUP BY 
        customers.company_name
    ORDER BY 
        total DESC
    )

    SELECT *
    FROM clients_to_marketing
    WHERE group_number >= 3;
    ```

3. **Top 10 Products**
    
    * Whata are the top-10 products according to the revenue?

    ```sql
    SELECT products.product_name, SUM(order_details.unit_price * order_details.quantity * (1.0 - order_details.discount)) AS sales
    FROM products
    INNER JOIN order_details ON order_details.product_id = products.product_id
    GROUP BY products.product_name
    ORDER BY sales DESC;
    ```

4. **Customers from TUK with revenue greather than 1000 Dólares**
    
    * Which customers from the United Kingdom have paid more than 1000 dollars?

    ```sql
    CREATE VIEW uk_clients_who_pay_more_then_1000 AS
    SELECT customers.contact_name, SUM(order_details.unit_price * order_details.quantity * (1.0 - order_details.discount) * 100) / 100 AS payments
    FROM customers
    INNER JOIN orders ON orders.customer_id = customers.customer_id
    INNER JOIN order_details ON order_details.order_id = orders.order_id
    WHERE LOWER(customers.country) = 'uk'
    GROUP BY customers.contact_name
    HAVING SUM(order_details.unit_price * order_details.quantity * (1.0 - order_details.discount)) > 1000;
    ```
