
BEGIN;
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS hstore;

    CREATE SCHEMA IF NOT EXISTS conecta_foods_users;
    CREATE SCHEMA IF NOT EXISTS conecta_foods_salables;
    CREATE SCHEMA IF NOT EXISTS conecta_foods_budgets;
    CREATE SCHEMA IF NOT EXISTS conecta_foods_discounts;
    CREATE SCHEMA IF NOT EXISTS conecta_foods_payments;
COMMIT;

BEGIN;
    CREATE TABLE IF NOT EXISTS conecta_foods_users.IMAGE (
        id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
        data BYTEA NOT NULL UNIQUE
    );
    CREATE INDEX idx_image_data ON conecta_foods_users.IMAGE(data);

    CREATE TABLE IF NOT EXISTS conecta_foods_discounts.ENUM_CURRENCY (
        currency VARCHAR(255) PRIMARY KEY,
        symbol VARCHAR(255) UNIQUE NOT NULL
    );

    CREATE TABLE IF NOT EXISTS conecta_foods_discounts.ENUM_DISCOUNT_TYPE (
        id SERIAL PRIMARY KEY,
        discount_type VARCHAR(255) UNIQUE NOT NULL
    );

    CREATE TABLE IF NOT EXISTS conecta_foods_payments.ENUM_PAYMENT_METHOD (
        id SERIAL PRIMARY KEY,
        payment_method_type VARCHAR(255) UNIQUE NOT NULL
    );
    
COMMIT;

BEGIN;
    CREATE TABLE IF NOT EXISTS conecta_foods_users.PROVIDER (
        name VARCHAR(255) NOT NULL PRIMARY KEY,
        description VARCHAR(255) NOT NULL,
        qualification SMALLINT CHECK (qualification >= 1 AND qualification <= 5),
        profile_image_id UUID NOT NULL,
        FOREIGN KEY (profile_image_id) REFERENCES conecta_foods_users.IMAGE(id)
    );
    CREATE INDEX idx_provider_qualification ON conecta_foods_users.PROVIDER(qualification);

    CREATE TABLE IF NOT EXISTS conecta_foods_discounts.DISCOUNT (
        id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
        discount_amount BIGINT NOT NULL,
        type_id INT NOT NULL,
        FOREIGN KEY (type_id) REFERENCES conecta_foods_discounts.ENUM_DISCOUNT_TYPE(id),
        UNIQUE (discount_amount, type_id)
    );
    CREATE INDEX idx_discount_amount ON conecta_foods_discounts.DISCOUNT(discount_amount);

    CREATE TABLE IF NOT EXISTS conecta_foods_users.BUYER_USER (
        name VARCHAR(255) PRIMARY KEY,
        qualification SMALLINT CHECK (qualification >= 1 AND qualification <= 5),
        profile_image_id UUID NOT NULL,
        FOREIGN KEY (profile_image_id) REFERENCES conecta_foods_users.IMAGE(id)
    );
COMMIT;

BEGIN;
    CREATE TABLE IF NOT EXISTS conecta_foods_salables.PRODUCT (
        name VARCHAR(255) NOT NULL,
        provider_name VARCHAR(255) NOT NULL,
        description VARCHAR(255) NOT NULL,
        unit_cost BIGINT NOT NULL,
        currency VARCHAR(255) NOT NULL,
        variation JSONB,
        image_id UUID NOT NULL,
        PRIMARY KEY (name, provider_name),
        FOREIGN KEY (provider_name) REFERENCES conecta_foods_users.PROVIDER(name),
        FOREIGN KEY (image_id) REFERENCES conecta_foods_users.IMAGE(id),
        FOREIGN KEY (currency) REFERENCES conecta_foods_discounts.ENUM_CURRENCY(currency)
    );
    CREATE INDEX idx_product_unit_cost ON conecta_foods_salables.PRODUCT(unit_cost);

    CREATE TABLE IF NOT EXISTS conecta_foods_salables.EVENT (
        name VARCHAR(255) NOT NULL,
        provider_name VARCHAR(255) NOT NULL,
        description VARCHAR(255) NOT NULL,
        PRIMARY KEY (name, provider_name),
        FOREIGN KEY (provider_name) REFERENCES conecta_foods_users.PROVIDER(name)
    );

    CREATE TABLE IF NOT EXISTS conecta_foods_salables.SERVICE (
        name VARCHAR(255) NOT NULL,
        provider_name VARCHAR(255) NOT NULL,
        description VARCHAR(255) NOT NULL,
        unit_cost BIGINT NOT NULL,
        currency VARCHAR(255) NOT NULL,
        variation JSONB,
        image_id UUID NOT NULL,
        PRIMARY KEY (name, provider_name),
        FOREIGN KEY (provider_name) REFERENCES conecta_foods_users.PROVIDER(name),
        FOREIGN KEY (image_id) REFERENCES conecta_foods_users.IMAGE(id),
        FOREIGN KEY (currency) REFERENCES conecta_foods_discounts.ENUM_CURRENCY(currency)
    );
    CREATE INDEX idx_service_unit_cost ON conecta_foods_salables.SERVICE(unit_cost);

    CREATE TABLE IF NOT EXISTS conecta_foods_budgets.BUDGET (
        id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
        creation_date TIMESTAMP NOT NULL,
        provider_name VARCHAR(255) NOT NULL,
        buyer_user_name VARCHAR(255) NOT NULL,
        discount_id UUID,
        FOREIGN KEY (provider_name) REFERENCES conecta_foods_users.PROVIDER(name),
        FOREIGN KEY (buyer_user_name) REFERENCES conecta_foods_users.BUYER_USER(name),
        FOREIGN KEY (discount_id) REFERENCES conecta_foods_discounts.DISCOUNT(id)
    );
    CREATE INDEX idx_budget_creation_date ON conecta_foods_budgets.BUDGET(creation_date);
COMMIT;

BEGIN;
    CREATE TABLE IF NOT EXISTS conecta_foods_budgets.BUDGET_SERVICE (
        service_name VARCHAR(255) NOT NULL,
        provider_name VARCHAR(255) NOT NULL,
        budget_id UUID NOT NULL,
        quantity INT NOT NULL,
        PRIMARY KEY (budget_id, service_name, provider_name),
        FOREIGN KEY (service_name, provider_name) REFERENCES conecta_foods_salables.SERVICE(name, provider_name),
        FOREIGN KEY (provider_name) REFERENCES conecta_foods_users.PROVIDER(name),
        FOREIGN KEY (budget_id) REFERENCES conecta_foods_budgets.BUDGET(id)
    );

    CREATE TABLE IF NOT EXISTS conecta_foods_budgets.BUDGET_PRODUCT (
        product_name VARCHAR(255) NOT NULL,
        provider_name VARCHAR(255) NOT NULL,
        budget_id UUID NOT NULL,
        quantity INT NOT NULL,
        PRIMARY KEY (budget_id, product_name, provider_name),
        FOREIGN KEY (product_name, provider_name) REFERENCES conecta_foods_salables.PRODUCT(name, provider_name),
        FOREIGN KEY (budget_id) REFERENCES conecta_foods_budgets.BUDGET(id)
    );

    CREATE TABLE IF NOT EXISTS conecta_foods_discounts.PRODUCT_DISCOUNT (
        product_name VARCHAR(255) NOT NULL,
        discount_id UUID NOT NULL,
        provider_name VARCHAR(255) NOT NULL,
        PRIMARY KEY (product_name, provider_name, discount_id),
        FOREIGN KEY (provider_name) REFERENCES conecta_foods_users.PROVIDER(name),
        FOREIGN KEY (product_name, provider_name) REFERENCES conecta_foods_salables.PRODUCT(name, provider_name),
        FOREIGN KEY (discount_id) REFERENCES conecta_foods_discounts.DISCOUNT(id)
    );

    CREATE TABLE IF NOT EXISTS conecta_foods_salables.AGENDA (
        id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
        date TIMESTAMP NOT NULL,
        unit_cost BIGINT NOT NULL,
        currency VARCHAR(255) NOT NULL,
        variation JSONB,
        event_name VARCHAR(255) NOT NULL,
        provider_name VARCHAR(255) NOT NULL,
        FOREIGN KEY (event_name, provider_name) REFERENCES conecta_foods_salables.EVENT(name, provider_name),
        FOREIGN KEY (provider_name) REFERENCES conecta_foods_users.PROVIDER(name),
        FOREIGN KEY (currency) REFERENCES conecta_foods_discounts.ENUM_CURRENCY(currency)
    );
    CREATE INDEX idx_agenda_date ON conecta_foods_salables.AGENDA(date);

    CREATE TABLE IF NOT EXISTS conecta_foods_discounts.SERVICE_DISCOUNT (
        service_name VARCHAR(255) NOT NULL,
        provider_name VARCHAR(255) NOT NULL,
        discount_id UUID NOT NULL,
        PRIMARY KEY (service_name, provider_name, discount_id),
        FOREIGN KEY (provider_name) REFERENCES conecta_foods_users.PROVIDER(name),
        FOREIGN KEY (service_name, provider_name) REFERENCES conecta_foods_salables.SERVICE(name, provider_name),
        FOREIGN KEY (discount_id) REFERENCES conecta_foods_discounts.DISCOUNT(id)
    );
COMMIT;

BEGIN;
    CREATE TABLE IF NOT EXISTS conecta_foods_users.CART_ITEM (
        id SERIAL PRIMARY KEY,
        user_buyer_name VARCHAR(255) NOT NULL,
        provider_name VARCHAR(255) NOT NULL,
        agenda_id UUID NULL,
        service_name VARCHAR(255) NULL,
        product_name VARCHAR(255) NULL,
        FOREIGN KEY (agenda_id) REFERENCES conecta_foods_salables.AGENDA(id),
        FOREIGN KEY (service_name, provider_name) REFERENCES conecta_foods_salables.SERVICE(name, provider_name),
        FOREIGN KEY (product_name, provider_name) REFERENCES conecta_foods_salables.PRODUCT(name, provider_name),
        FOREIGN KEY (user_buyer_name) REFERENCES conecta_foods_users.BUYER_USER(name)
    );

    CREATE TABLE IF NOT EXISTS conecta_foods_budgets.BUDGET_AGENDA (
        agenda_id UUID NOT NULL,
        budget_id UUID NOT NULL,
        PRIMARY KEY (budget_id, agenda_id),
        FOREIGN KEY (agenda_id) REFERENCES conecta_foods_salables.AGENDA(id),
        FOREIGN KEY (budget_id) REFERENCES conecta_foods_budgets.BUDGET(id)
    );

    CREATE TABLE IF NOT EXISTS conecta_foods_discounts.AGENDA_DISCOUNT (
        agenda_discount_id UUID NOT NULL,
        discount_id UUID NOT NULL,
        PRIMARY KEY (agenda_discount_id, discount_id),
        FOREIGN KEY (agenda_discount_id) REFERENCES conecta_foods_salables.AGENDA(id),
        FOREIGN KEY (discount_id) REFERENCES conecta_foods_discounts.DISCOUNT(id)
    );

    CREATE TABLE IF NOT EXISTS conecta_foods_payments.RESERVATION (
        agenda_id UUID PRIMARY KEY,
        date TIMESTAMP NOT NULL,
        payment_method_id INT NOT NULL,
        FOREIGN KEY (agenda_id) REFERENCES conecta_foods_salables.AGENDA(id),
        FOREIGN KEY (payment_method_id) REFERENCES conecta_foods_payments.ENUM_PAYMENT_METHOD(id)
    );
COMMIT;

BEGIN;
    CREATE TABLE IF NOT EXISTS conecta_foods_users.CART (
        buyer_user_name VARCHAR(255),
        cart_item_id SERIAL NOT NULL,
        PRIMARY KEY (buyer_user_name, cart_item_id),
        FOREIGN KEY (buyer_user_name) REFERENCES conecta_foods_users.BUYER_USER(name),
        FOREIGN KEY (cart_item_id) REFERENCES conecta_foods_users.CART_ITEM(id)
    );
COMMIT;


BEGIN;
    
    
    INSERT INTO conecta_foods_payments.ENUM_PAYMENT_METHOD (payment_method_type) VALUES
        ('Credit Card'),
        ('PayPal'),
        ('Bank Transfer'),
        ('Cash'),
        ('Cryptocurrency'),
        ('Mobile Payment'),
        ('Check'),
        ('Money Order'),
        ('Gift Card'),
        ('Digital Wallet')
    ON CONFLICT (payment_method_type) DO NOTHING;

    INSERT INTO conecta_foods_discounts.ENUM_DISCOUNT_TYPE (discount_type) VALUES
        ('Percentage'),
        ('Fixed Amount')
    ON CONFLICT (discount_type) DO NOTHING;

    INSERT INTO conecta_foods_discounts.ENUM_CURRENCY (currency, symbol) VALUES 
    ('Peso Uruguayo', '$U'),
    ('Peso Argentino', '$A'),
    ('Real', 'R$'),
    ('Dólar', 'USD'),
    ('Euro', '€')
    ON CONFLICT (currency) DO NOTHING;

    INSERT INTO conecta_foods_users.IMAGE (data) VALUES
        (E'\\x01'),
        (E'\\x02'),
        (E'\\x03'),
        (E'\\x04'),
        (E'\\x05'),
        (E'\\x06'),
        (E'\\x07'),
        (E'\\x08'),
        (E'\\x09'),
        (E'\\x0a')
    ON CONFLICT (data) DO NOTHING;

    INSERT INTO conecta_foods_discounts.DISCOUNT(discount_amount, type_id) VALUES
        (10, 1),
        (500, 2),
        (15, 1),
        (200, 2),
        (30, 1),
        (50, 2),
        (25, 1),
        (100, 2),
        (10, 1),
        (75, 2)
    ON CONFLICT (discount_amount, type_id) DO NOTHING;
COMMIT;

BEGIN;
    INSERT INTO conecta_foods_users.PROVIDER (name, description, qualification, profile_image_id) VALUES    
        ('Provider 1', 'Provider 1 Description', 1, (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x01')),
        ('Provider 2', 'Provider 2 Description', 2, (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x02')),
        ('Provider 3', 'Provider 3 Description', 3, (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x03')),
        ('Provider 4', 'Provider 4 Description', 4, (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x04')),
        ('Provider 5', 'Provider 5 Description', 5, (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x05')),
        ('Provider 6', 'Provider 6 Description', 1, (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x06')),
        ('Provider 7', 'Provider 7 Description', 2, (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x07')),
        ('Provider 8', 'Provider 8 Description', 3, (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x08')),
        ('Provider 9', 'Provider 9 Description', 4, (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x09')),
        ('Provider 10', 'Provider 10 Description', 5, (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x0a'))
    ON CONFLICT (name) DO NOTHING;

    INSERT INTO conecta_foods_salables.PRODUCT (name, description, unit_cost, currency, variation, image_id, provider_name) VALUES
        ('Product 1', 'Product 1 Description', 100, 'Peso Uruguayo', '{"size": "Large", "color": "Red"}', (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x01'), 'Provider 1'),
        ('Product 2', 'Product 2 Description', 100, 'Peso Uruguayo', '{"size": "Large", "color": "Red"}', (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x01'), 'Provider 1'),
        ('Product 3', 'Product 3 Description', 100, 'Peso Uruguayo', '{"size": "Large", "color": "Red"}', (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x01'), 'Provider 1'),
        ('Product 2', 'Product 2 Description', 150, 'Peso Uruguayo', '{"size": "Medium", "color": "Blue"}', (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x02'), 'Provider 2'),
        ('Product 3', 'Product 3 Description', 120, 'Peso Uruguayo', '{"size": "Small", "color": "Green"}', (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x03'), 'Provider 3'),
        ('Product 4', 'Product 4 Description', 200, 'Peso Uruguayo', '{"size": "XL", "color": "Black"}', (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x04'), 'Provider 4'),
        ('Product 5', 'Product 5 Description', 180, 'Peso Uruguayo', '{"size": "XXL", "color": "White"}', (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x05'), 'Provider 5'),
        ('Product 6', 'Product 6 Description', 250, 'Peso Uruguayo', '{"size": "M", "color": "Yellow"}', (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x06'), 'Provider 6'),
        ('Product 7', 'Product 7 Description', 300, 'Peso Uruguayo', '{"size": "S", "color": "Purple"}', (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x07'), 'Provider 7'),
        ('Product 8', 'Product 8 Description', 180, 'Peso Uruguayo', '{"size": "L", "color": "Orange"}', (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x08'), 'Provider 8'),
        ('Product 9', 'Product 9 Description', 220, 'Peso Uruguayo', '{"size": "XL", "color": "Brown"}', (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x09'), 'Provider 9'),
        ('Product 10', 'Product 10 Description', 200, 'Peso Uruguayo', '{"size": "M", "color": "Gray"}', (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x0a'), 'Provider 10')
    ON CONFLICT (name, provider_name) DO NOTHING;

    INSERT INTO conecta_foods_salables.SERVICE (name, description, unit_cost, currency, variation, provider_name, image_id) VALUES
        ('Service 1', 'Description for Service 1', 300, 'Peso Uruguayo', '{"option1": "value1", "option2": "value2"}', 'Provider 1', (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x01')),
        ('Service 2', 'Description for Service 2', 500, 'Peso Uruguayo', '{"option1": "value1", "option2": "value2"}', 'Provider 2', (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x02')),
        ('Service 3', 'Description for Service 3', 400, 'Peso Uruguayo', '{"option1": "value1", "option2": "value2"}', 'Provider 3', (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x03')),
        ('Service 4', 'Description for Service 4', 600, 'Peso Uruguayo', '{"option1": "value1", "option2": "value2"}', 'Provider 4', (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x04')),
        ('Service 5', 'Description for Service 5', 450, 'Peso Uruguayo', '{"option1": "value1", "option2": "value2"}', 'Provider 5', (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x05')),
        ('Service 6', 'Description for Service 6', 700, 'Peso Uruguayo', '{"option1": "value1", "option2": "value2"}', 'Provider 6', (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x06')),
        ('Service 7', 'Description for Service 7', 550, 'Peso Uruguayo', '{"option1": "value1", "option2": "value2"}', 'Provider 7', (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x07')),
        ('Service 8', 'Description for Service 8', 800, 'Peso Uruguayo', '{"option1": "value1", "option2": "value2"}', 'Provider 8', (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x08')),
        ('Service 9', 'Description for Service 9', 650, 'Peso Uruguayo', '{"option1": "value1", "option2": "value2"}', 'Provider 9', (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x09')),
        ('Service 10', 'Description for Service 10', 900, 'Peso Uruguayo', '{"option1": "value1", "option2": "value2"}', 'Provider 10', (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x0a'))
    ON CONFLICT (name, provider_name) DO NOTHING;

    INSERT INTO conecta_foods_users.BUYER_USER (name, qualification, profile_image_id) VALUES
        ('Buyer 1', 4,  (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x01')),
        ('Buyer 2', 3,  (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x02')),
        ('Buyer 3', 5,  (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x03')),
        ('Buyer 4', 4,  (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x04')),
        ('Buyer 5', 5,  (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x05')),
        ('Buyer 6', 4,  (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x06')),
        ('Buyer 7', 3,  (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x07')),
        ('Buyer 8', 5,  (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x08')),
        ('Buyer 9', 4,  (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x09')),
        ('Buyer 10', 3, (SELECT id FROM conecta_foods_users.IMAGE WHERE data = E'\\x0a'))
    ON CONFLICT (name) DO NOTHING;

    INSERT INTO conecta_foods_budgets.BUDGET (creation_date, provider_name, buyer_user_name, discount_id) VALUES
        ('2024-03-06', 'Provider 1', 'Buyer 1', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 10 AND type_id = 1)),
        ('2024-03-07', 'Provider 2', 'Buyer 2', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 500 AND type_id = 2)),
        ('2024-03-08', 'Provider 3', 'Buyer 3', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 15 AND type_id = 1)),
        ('2024-03-09', 'Provider 4', 'Buyer 4', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 200 AND type_id = 2)),
        ('2024-03-10', 'Provider 5', 'Buyer 5', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 30 AND type_id = 1)),
        ('2024-03-11', 'Provider 6', 'Buyer 6', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 50 AND type_id = 2)),
        ('2024-03-12', 'Provider 7', 'Buyer 7', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 25 AND type_id = 1)),
        ('2024-03-13', 'Provider 8', 'Buyer 8', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 100 AND type_id = 2)),
        ('2024-03-14', 'Provider 9', 'Buyer 9', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 10 AND type_id = 1)),
        ('2024-03-15', 'Provider 10', 'Buyer 10', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 75 AND type_id = 2));

    INSERT INTO conecta_foods_discounts.PRODUCT_DISCOUNT (product_name, provider_name, discount_id)
    VALUES
        ('Product 1', 'Provider 1', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 10 AND type_id = 1)),
        ('Product 2', 'Provider 2', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 500 AND type_id = 2)),
        ('Product 3', 'Provider 3', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 15 AND type_id = 1)),
        ('Product 4', 'Provider 4', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 200 AND type_id = 2)),
        ('Product 5', 'Provider 5', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 30 AND type_id = 1)),
        ('Product 6', 'Provider 6', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 50 AND type_id = 2)),
        ('Product 7', 'Provider 7', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 25 AND type_id = 1)),
        ('Product 8', 'Provider 8', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 100 AND type_id = 2)),
        ('Product 9', 'Provider 9', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 10 AND type_id = 1)),
        ('Product 10', 'Provider 10', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 75 AND type_id = 2));

    INSERT INTO conecta_foods_discounts.SERVICE_DISCOUNT (service_name, provider_name, discount_id) VALUES
        ('Service 1', 'Provider 1', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 10 AND type_id = 1)),
        ('Service 2', 'Provider 2', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 500 AND type_id = 2)),
        ('Service 3', 'Provider 3', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 15 AND type_id = 1)),
        ('Service 4', 'Provider 4', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 200 AND type_id = 2)),
        ('Service 5', 'Provider 5', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 30 AND type_id = 1)),
        ('Service 6', 'Provider 6', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 50 AND type_id = 2)),
        ('Service 7', 'Provider 7', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 25 AND type_id = 1)),
        ('Service 8', 'Provider 8', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 100 AND type_id = 2)),
        ('Service 9', 'Provider 9', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 10 AND type_id = 1)),
        ('Service 10', 'Provider 10', (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 75 AND type_id = 2));
COMMIT;

BEGIN;
    INSERT INTO conecta_foods_salables.EVENT (name, provider_name, description) VALUES
        ('Event 1', 'Provider 1', 'Description for Event 1'),
        ('Event 2', 'Provider 2', 'Description for Event 2'),
        ('Event 3', 'Provider 3', 'Description for Event 3'),
        ('Event 4', 'Provider 4', 'Description for Event 4'),
        ('Event 5', 'Provider 5', 'Description for Event 5'),
        ('Event 6', 'Provider 6', 'Description for Event 6'),
        ('Event 7', 'Provider 7', 'Description for Event 7'),
        ('Event 8', 'Provider 8', 'Description for Event 8'),
        ('Event 9', 'Provider 9', 'Description for Event 9'),
        ('Event 10', 'Provider 10', 'Description for Event 10')
    ON CONFLICT (name, provider_name) DO NOTHING;
    
    INSERT INTO conecta_foods_budgets.BUDGET_PRODUCT (product_name, provider_name, quantity, budget_id) VALUES
        ('Product 1', 'Provider 1', 1, (SELECT id FROM conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 1')),
        ('Product 2', 'Provider 1', 1, (SELECT id FROM conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 1')),
        ('Product 3', 'Provider 1', 1, (SELECT id FROM conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 1')),
        ('Product 2', 'Provider 2', 1, (SELECT id FROM conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 2')),
        ('Product 3', 'Provider 3', 3, (SELECT id FROM conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 3')),
        ('Product 4', 'Provider 4', 2, (SELECT id FROM conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 4')),
        ('Product 5', 'Provider 5', 1, (SELECT id FROM conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 5')),
        ('Product 6', 'Provider 6', 4, (SELECT id FROM conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 6')),
        ('Product 7', 'Provider 7', 2, (SELECT id FROM conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 7')),
        ('Product 8', 'Provider 8', 1, (SELECT id FROM conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 8')),
        ('Product 9', 'Provider 9', 3, (SELECT id FROM conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 9')),
        ('Product 10', 'Provider 10', 2, (SELECT id FROM conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 10'));

    INSERT INTO conecta_foods_budgets.BUDGET_SERVICE (service_name, provider_name, quantity, budget_id) VALUES
        ('Service 1', 'Provider 1', 1, (SELECT id FROM conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 1')),
        ('Service 2', 'Provider 2', 2, (SELECT id FROM conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 2')),
        ('Service 3', 'Provider 3', 3, (SELECT id FROM conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 3')),
        ('Service 4', 'Provider 4', 1, (SELECT id FROM conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 4')),
        ('Service 5', 'Provider 5', 2, (SELECT id FROM conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 5')),
        ('Service 6', 'Provider 6', 3, (SELECT id FROM conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 6')),
        ('Service 7', 'Provider 7', 1, (SELECT id FROM conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 7')),
        ('Service 8', 'Provider 8', 2, (SELECT id FROM conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 8')),
        ('Service 9', 'Provider 9', 3, (SELECT id FROM conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 9')),
        ('Service 10', 'Provider 10', 1, (SELECT id FROM conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 10'));

COMMIT;  

BEGIN;
    INSERT INTO conecta_foods_salables.AGENDA (date, unit_cost, currency, variation, event_name, provider_name)
    VALUES
        ('2024-03-06', 100, 'Peso Uruguayo', '{"key1": "value1", "key2": "value2"}', 'Event 1', 'Provider 1'),
        ('2024-03-07', 150, 'Peso Uruguayo', '{"key1": "value1", "key2": "value2"}', 'Event 2', 'Provider 2'),
        ('2024-03-08', 200, 'Peso Uruguayo', '{"key1": "value1", "key2": "value2"}', 'Event 3', 'Provider 3'),
        ('2024-03-09', 250, 'Peso Uruguayo', '{"key1": "value1", "key2": "value2"}', 'Event 4', 'Provider 4'),
        ('2024-03-10', 300, 'Peso Uruguayo', '{"key1": "value1", "key2": "value2"}', 'Event 5', 'Provider 5'),
        ('2024-03-11', 350, 'Peso Uruguayo', '{"key1": "value1", "key2": "value2"}', 'Event 6', 'Provider 6'),
        ('2024-03-12', 400, 'Peso Uruguayo', '{"key1": "value1", "key2": "value2"}', 'Event 7', 'Provider 7'),
        ('2024-03-13', 450, 'Peso Uruguayo', '{"key1": "value1", "key2": "value2"}', 'Event 8', 'Provider 8'),
        ('2024-03-14', 500, 'Peso Uruguayo', '{"key1": "value1", "key2": "value2"}', 'Event 9', 'Provider 9'),
        ('2024-03-15', 550, 'Peso Uruguayo', '{"key1": "value1", "key2": "value2"}', 'Event 10', 'Provider 10');

COMMIT;

BEGIN;
    INSERT INTO conecta_foods_users.CART_ITEM (user_buyer_name, provider_name, agenda_id) VALUES
        ('Buyer 1',  'Provider 1',  (SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-06')),
        ('Buyer 2',  'Provider 2',  (SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-07')),
        ('Buyer 3',  'Provider 3',  (SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-08')),
        ('Buyer 4',  'Provider 4',  (SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-09')),
        ('Buyer 5',  'Provider 5',  (SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-10')),
        ('Buyer 6',  'Provider 6',  (SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-11')),
        ('Buyer 7',  'Provider 7',  (SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-12')),
        ('Buyer 8',  'Provider 8',  (SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-13')),
        ('Buyer 9',  'Provider 9',  (SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-14')),
        ('Buyer 10', 'Provider 10', (SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-15'));
    
    INSERT INTO conecta_foods_users.CART_ITEM (user_buyer_name, provider_name, service_name) VALUES
        ('Buyer 1',  'Provider 1', 'Service 1'),
        ('Buyer 2',  'Provider 2', 'Service 2'),
        ('Buyer 3',  'Provider 3', 'Service 3'),
        ('Buyer 4',  'Provider 4', 'Service 4'),
        ('Buyer 5',  'Provider 5', 'Service 5'),
        ('Buyer 6',  'Provider 6', 'Service 6'),
        ('Buyer 7',  'Provider 7', 'Service 7'),
        ('Buyer 8',  'Provider 8', 'Service 8'),
        ('Buyer 9',  'Provider 9', 'Service 9'),
        ('Buyer 10', 'Provider 10','Service 10');
    
    INSERT INTO conecta_foods_users.CART_ITEM (user_buyer_name, provider_name, product_name) VALUES
        ('Buyer 1',  'Provider 1',  'Product 1'),
        ('Buyer 2',  'Provider 2',  'Product 2'),
        ('Buyer 3',  'Provider 3',  'Product 3'),
        ('Buyer 4',  'Provider 4',  'Product 4'),
        ('Buyer 5',  'Provider 5',  'Product 5'),
        ('Buyer 6',  'Provider 6',  'Product 6'),
        ('Buyer 7',  'Provider 7',  'Product 7'),
        ('Buyer 8',  'Provider 8',  'Product 8'),
        ('Buyer 9',  'Provider 9',  'Product 9'),
        ('Buyer 10', 'Provider 10', 'Product 10');

    INSERT INTO conecta_foods_payments.RESERVATION (agenda_id, date, payment_method_id) VALUES
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-06'), '2024-03-07', 1),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-07'), '2024-03-08', 2),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-08'), '2024-03-09', 3),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-09'), '2024-03-10', 4),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-10'), '2024-03-11', 5),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-11'), '2024-03-12', 6),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-12'), '2024-03-13', 7),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-13'), '2024-03-14', 8),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-14'), '2024-03-15', 9),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-15'), '2024-03-16', 10);

    INSERT INTO conecta_foods_discounts.AGENDA_DISCOUNT (agenda_discount_id, discount_id)
    VALUES
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-06'), (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 10 AND type_id = 1)),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-07'), (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 500 AND type_id = 2)),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-08'), (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 15 AND type_id = 1)),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-09'), (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 200 AND type_id = 2)),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-10'), (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 30 AND type_id = 1)),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-11'), (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 50 AND type_id = 2)),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-12'), (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 25 AND type_id = 1)),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-13'), (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 100 AND type_id = 2)),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-14'), (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 10 AND type_id = 1)),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-15'), (SELECT id FROM conecta_foods_discounts.DISCOUNT WHERE discount_amount = 75 AND type_id = 2));

    INSERT INTO conecta_foods_budgets.BUDGET_AGENDA (agenda_id, budget_id) VALUES
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-06'), (SELECT id FROM  conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 1')),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-07'), (SELECT id FROM  conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 2')),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-08'), (SELECT id FROM  conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 3')),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-09'), (SELECT id FROM  conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 4')),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-10'), (SELECT id FROM  conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 5')),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-11'), (SELECT id FROM  conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 6')),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-12'), (SELECT id FROM  conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 7')),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-13'), (SELECT id FROM  conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 8')),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-14'), (SELECT id FROM  conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 9')),
        ((SELECT id FROM conecta_foods_salables.AGENDA WHERE date = '2024-03-15'), (SELECT id FROM  conecta_foods_budgets.BUDGET WHERE provider_name = 'Provider 10'));
COMMIT;

BEGIN;
    INSERT INTO conecta_foods_users.CART (cart_item_id, buyer_user_name) VALUES   
        (1, 'Buyer 1'),
        (2, 'Buyer 2'),
        (3, 'Buyer 3'),
        (4, 'Buyer 4'),
        (5, 'Buyer 5'),
        (6, 'Buyer 6'),
        (7, 'Buyer 7'),
        (8, 'Buyer 8'),
        (9, 'Buyer 9'),
        (10, 'Buyer 10'),
        (11, 'Buyer 1'),
        (12, 'Buyer 2'),
        (13, 'Buyer 3'),
        (14, 'Buyer 4'),
        (15, 'Buyer 5'),
        (16, 'Buyer 6'),
        (17, 'Buyer 7'),
        (18, 'Buyer 8'),
        (19, 'Buyer 9'),
        (20, 'Buyer 10'),
        (21, 'Buyer 1'),
        (22, 'Buyer 2'),
        (23, 'Buyer 3'),
        (24, 'Buyer 4'),
        (25, 'Buyer 5'),
        (26, 'Buyer 6'),
        (27, 'Buyer 7'),
        (28, 'Buyer 8'),
        (29, 'Buyer 9'),
        (30, 'Buyer 10');
COMMIT;

BEGIN;
    CREATE OR REPLACE VIEW conecta_foods_budgets.budget_products AS
    SELECT
        B.id as budget_id,
        B.creation_date,
        B.provider_name,
        B.buyer_user_name,
        BP.product_name
    FROM
        conecta_foods_budgets.BUDGET B
    INNER JOIN conecta_foods_budgets.BUDGET_PRODUCT BP ON B.id = BP.budget_id;

    CREATE OR REPLACE VIEW conecta_foods_budgets.budget_services AS
    SELECT
        B.id as budget_id,
        B.creation_date,
        B.provider_name,
        B.buyer_user_name,
        BS.service_name
    FROM
        conecta_foods_budgets.BUDGET B
    INNER JOIN conecta_foods_budgets.BUDGET_SERVICE BS ON B.id = BS.budget_id;


    CREATE OR REPLACE VIEW conecta_foods_budgets.budget_agendas AS
    SELECT
        B.creation_date,
        B.id as budget_id,
        B.provider_name,
        B.buyer_user_name,
        event_name AS agenda_name,
        A.id AS agenda_id,
        date
    FROM
        conecta_foods_budgets.BUDGET B
    LEFT JOIN conecta_foods_budgets.BUDGET_AGENDA  BA ON B.id = BA.budget_id
    LEFT JOIN (
                    SELECT id, event_name , A.provider_name, A.date, A.unit_cost, A.currency
                    FROM conecta_foods_salables.EVENT E
                    LEFT JOIN conecta_foods_salables.AGENDA A ON E.name = A.event_name AND E.provider_name = A.provider_name
                    GROUP BY E.name, E.provider_name, A.id, A.event_name
                ) A ON A.id = BA.agenda_id;
COMMIT;

BEGIN;
    CREATE OR REPLACE VIEW conecta_foods_discounts.budget_products_discounts AS
    SELECT
        BP.budget_id,
        BP.creation_date,
        BP.provider_name,
        BP.buyer_user_name,
        BP.product_name,
        D.discount_amount,
        D.type_id
    FROM
        conecta_foods_budgets.budget_products BP
    INNER JOIN conecta_foods_discounts.PRODUCT_DISCOUNT PD ON PD.product_name = BP.product_name
    INNER JOIN conecta_foods_discounts.DISCOUNT D ON PD.discount_id = D.id
    INNER JOIN conecta_foods_discounts.ENUM_DISCOUNT_TYPE EDT ON EDT.id = D.type_id;

    CREATE OR REPLACE VIEW conecta_foods_discounts.budget_services_discounts AS
    SELECT
        BS.budget_id,
        BS.creation_date,
        BS.provider_name,
        BS.buyer_user_name,
        BS.service_name,
        D.discount_amount,
        EDT.discount_type
    FROM
        conecta_foods_budgets.budget_services BS
    INNER JOIN conecta_foods_discounts.SERVICE_DISCOUNT SD ON SD.service_name = BS.service_name
    INNER JOIN conecta_foods_discounts.DISCOUNT D ON SD.discount_id = D.id
    INNER JOIN conecta_foods_discounts.ENUM_DISCOUNT_TYPE EDT ON EDT.id = D.type_id;

    CREATE OR REPLACE VIEW conecta_foods_discounts.budget_agendas_discounts AS
    SELECT
        BA.buyer_user_name,
        BA.budget_id,
        BA.creation_date,
        A.id AS agenda_id,
        BA.agenda_name,
        A.provider_name,
        D.discount_amount,
        EDT.discount_type
    FROM
        conecta_foods_budgets.budget_agendas BA
    INNER JOIN conecta_foods_discounts.AGENDA_DISCOUNT AD ON AD.agenda_discount_id = BA.agenda_id
    INNER JOIN conecta_foods_discounts.DISCOUNT D ON AD.discount_id = D.id
    INNER JOIN conecta_foods_discounts.ENUM_DISCOUNT_TYPE EDT ON EDT.id = D.type_id
    LEFT JOIN (
        SELECT id, event_name , A.provider_name, A.date, A.unit_cost, A.currency
        FROM conecta_foods_salables.EVENT E
        LEFT JOIN conecta_foods_salables.AGENDA A ON E.name = A.event_name AND E.provider_name = A.provider_name
        GROUP BY E.name, E.provider_name, A.id, A.event_name
    ) A ON A.id = BA.agenda_id;
COMMIT;

BEGIN;
    CREATE OR REPLACE VIEW conecta_foods_discounts.budget_products_with_discounts AS
    SELECT
        BP.budget_id,
        BP.creation_date,
        BP.provider_name,
        BP.buyer_user_name,
        BP.product_name,
        D.discount_amount,
        EDT.discount_type
    FROM
        conecta_foods_budgets.budget_products BP
    LEFT JOIN conecta_foods_discounts.PRODUCT_DISCOUNT PD ON PD.product_name = BP.product_name
    LEFT JOIN conecta_foods_discounts.DISCOUNT D ON PD.discount_id = D.id
    LEFT JOIN conecta_foods_discounts.ENUM_DISCOUNT_TYPE EDT ON EDT.id = D.type_id;

    CREATE OR REPLACE VIEW conecta_foods_discounts.budget_services_with_discounts AS
    SELECT
        BS.budget_id,
        BS.creation_date,
        BS.provider_name,
        BS.buyer_user_name,
        BS.service_name,
        D.discount_amount,
        EDT.discount_type
    FROM
        conecta_foods_budgets.budget_services BS
    LEFT JOIN conecta_foods_discounts.SERVICE_DISCOUNT SD ON SD.service_name = BS.service_name
    LEFT JOIN conecta_foods_discounts.DISCOUNT D ON SD.discount_id = D.id
    LEFT JOIN conecta_foods_discounts.ENUM_DISCOUNT_TYPE EDT ON EDT.id = D.type_id;

    CREATE OR REPLACE VIEW conecta_foods_discounts.budget_agendas_with_discounts AS
    SELECT
        BA.creation_date,
        BA.budget_id,
        BA.provider_name,
        BA.buyer_user_name,
        BA.agenda_name,
        D.discount_amount,
        EDT.discount_type
    FROM
        conecta_foods_discounts.budget_agendas_discounts BA
    LEFT JOIN conecta_foods_discounts.AGENDA_DISCOUNT AD ON AD.agenda_discount_id = BA.agenda_id
    LEFT JOIN conecta_foods_discounts.DISCOUNT D ON AD.discount_id = D.id
    LEFT JOIN conecta_foods_discounts.ENUM_DISCOUNT_TYPE EDT ON EDT.id = D.type_id;
COMMIT;

BEGIN;
    CREATE OR REPLACE VIEW conecta_foods_budgets.budget_all AS
    SELECT 
        COALESCE(budget_products_with_discounts.budget_id, conecta_foods_discounts.budget_services_with_discounts.budget_id, conecta_foods_discounts.budget_agendas_with_discounts.budget_id) AS budget_id,
        COALESCE(budget_products_with_discounts.provider_name, conecta_foods_discounts.budget_services_with_discounts.provider_name, conecta_foods_discounts.budget_agendas_with_discounts.provider_name) AS provider_name,
        COALESCE(budget_products_with_discounts.creation_date, conecta_foods_discounts.budget_services_with_discounts.creation_date, conecta_foods_discounts.budget_agendas_with_discounts.creation_date) AS creation_date,
        COALESCE(budget_products_with_discounts.buyer_user_name, conecta_foods_discounts.budget_services_with_discounts.buyer_user_name, conecta_foods_discounts.budget_agendas_with_discounts.buyer_user_name) AS buyer_user_name,
        COALESCE(budget_products_with_discounts.product_name, conecta_foods_discounts.budget_services_with_discounts.service_name, conecta_foods_discounts.budget_agendas_with_discounts.agenda_name) AS name,
        COALESCE(budget_products_with_discounts.discount_amount, conecta_foods_discounts.budget_services_with_discounts.discount_amount, conecta_foods_discounts.budget_agendas_with_discounts.discount_amount) AS discount_amount, 
        COALESCE(budget_products_with_discounts.discount_type, conecta_foods_discounts.budget_services_with_discounts.discount_type, conecta_foods_discounts.budget_agendas_with_discounts.discount_type) AS discount_type
    FROM conecta_foods_discounts.budget_products_with_discounts
    FULL JOIN conecta_foods_discounts.budget_services_with_discounts ON 1 = 0
    FULL JOIN conecta_foods_discounts.budget_agendas_with_discounts ON 1 = 0
    ORDER BY provider_name ASC, budget_id DESC;

    SELECT
        budget_id,
        provider_name,
        creation_date,
        buyer_user_name,
        discount_type,
        discount_amount,
        ARRAY_AGG(name) AS names
    FROM
        conecta_foods_budgets.budget_all
    GROUP BY
        budget_id,
        provider_name,
        creation_date,
        buyer_user_name,
        discount_type,
        discount_amount
    ORDER BY provider_name ASC, buyer_user_name DESC, creation_date DESC;
COMMIT;

BEGIN;
    CREATE OR REPLACE VIEW conecta_foods_users.cart_all_products AS
    SELECT
       C.buyer_user_name,
       CI.user_buyer_name,
       CI.provider_name,
       CI.product_name AS item_name
    FROM
        conecta_foods_users.CART C
    INNER JOIN conecta_foods_users.CART_ITEM CI ON CI.id = C.cart_item_id
    INNER JOIN conecta_foods_salables.PRODUCT P ON P.name = CI.product_name;
    
    CREATE OR REPLACE VIEW conecta_foods_users.cart_all_services AS
    SELECT
       C.buyer_user_name,
       CI.user_buyer_name,
       CI.provider_name,
       CI.service_name AS item_name
    FROM
        conecta_foods_users.CART C
    INNER JOIN conecta_foods_users.CART_ITEM CI ON CI.id = C.cart_item_id
    INNER JOIN conecta_foods_salables.SERVICE S ON S.name = CI.service_name;
    
    CREATE OR REPLACE VIEW conecta_foods_users.cart_all_agendas AS
    SELECT
       C.buyer_user_name,
       CI.user_buyer_name,
       CI.provider_name,
       event_name AS item_name
    FROM
        conecta_foods_users.CART C
    INNER JOIN conecta_foods_users.CART_ITEM CI ON CI.id = C.cart_item_id
    INNER JOIN (
        SELECT id, event_name , A.provider_name, A.date, A.unit_cost, A.currency
        FROM conecta_foods_salables.EVENT E
        LEFT JOIN conecta_foods_salables.AGENDA A ON E.name = A.event_name AND E.provider_name = A.provider_name
        GROUP BY E.name, E.provider_name, A.id, A.event_name
    ) A ON A.id = CI.agenda_id;
COMMIT;

BEGIN;
	CREATE OR REPLACE VIEW conecta_foods_users.cart_all AS
    SELECT * FROM conecta_foods_users.cart_all_agendas 
    UNION SELECT * FROM conecta_foods_users.cart_all_products 
    UNION SELECT * FROM conecta_foods_users.cart_all_services;
COMMIT;

BEGIN;  
    CREATE OR REPLACE VIEW conecta_foods_users.cart_all_grouped AS
    SELECT 
        buyer_user_name,
        user_buyer_name,
        provider_name,
        ARRAY_AGG(item_name)
    FROM conecta_foods_users.cart_all CA
    GROUP BY buyer_user_name, user_buyer_name, provider_name
    ORDER BY user_buyer_name ASC, buyer_user_name DESC;
COMMIT;

-- TODO: Procedimientos, Funciones, Redundancia, Usuario Admin, Matriz de Roles y Permisos
-- TODO: ADD Curency ENUM to views
-- TODO: Revisar MER y poner correctamente las relaciones