// Importa as bibliotecas
const express = require('express');
const { Pool } = require('pg');

// Importações para o Socket.IO
const http = require('http'); // Módulo 'http' nativo do Node
const { Server } = require("socket.io"); // Biblioteca do Socket.IO

// =================================================================
// CONFIGURAÇÃO DO SERVIDOR EXPRESS E SOCKET.IO
// =================================================================
const app = express();
const PORT = 3000;

// Middleware para entender JSON (o "tradutor" que faltava!)
app.use(express.json());

// O Express cria o app, mas o 'http' nativo que "serve" ele
const server = http.createServer(app);

// O Socket.IO vai "ouvir" o servidor http
const io = new Server(server, {
    cors: {
        origin: "*", // Permite que qualquer app (React Native, etc.) se conecte
        methods: ["GET", "POST"]
    }
});

// =================================================================
// CONFIGURAÇÃO DO BANCO DE DADOS (POOL)
// =================================================================
// Desta vez, não fechamos o pool. Ele fica aberto
// para receber conexões enquanto o servidor estiver rodando.
const pool = new Pool({
    user: 'postgres',
    host: 'localhost',
    database: 'BeDeli',
    password: '250105', // <<== MUDE AQUI PARA A SUA SENHA
    port: 5432,
});

// =================================================================
// NOSSAS "ROTAS" (ENDPOINTS DA API)
// =================================================================

/**
 * Rota de teste simples
 * Quando alguém acessar http://localhost:3000/
 * ele responde com "Servidor BeDeli está no ar!"
 */
app.get('/', (req, res) => {
    res.send('Servidor BeDeli está no ar!');
});

/**
 * Rota para testar a conexão com o banco de dados
 * Quando alguém acessar http://localhost:3000/test-db
 */
app.get('/test-db', async (req, res) => {
    try {
        const client = await pool.connect();
        const result = await client.query('SELECT NOW()');
        client.release();
        
        // Envia a resposta de sucesso de volta para o navegador
        res.json({
            message: "Conexão com o banco de dados bem-sucedida!",
            timestamp: result.rows[0].now
        });
        
    } catch (err) {
        // Se der erro, envia uma resposta de erro (código 500)
        console.error(err);
        res.status(500).json({
            error: "Erro ao conectar ao banco de dados",
            details: err.message
        });
    }
});

/**
 * Rota [GET] /api/products
 * Busca e retorna todos os produtos cadastrados no banco.
 * Será usada pelo App do Cliente e pelo Dashboard da Loja.
 */
app.get('/api/products', async (req, res) => {
    try {
        // 1. Conecta ao banco
        const client = await pool.connect();
        
        // 2. Prepara a consulta SQL
        const queryText = 'SELECT * FROM Products ORDER BY name ASC';
        
        // 3. Executa a consulta
        const result = await client.query(queryText);
        
        // 4. Libera o cliente
        client.release();
        
        // 5. Envia os resultados (as "linhas" da tabela) como JSON
        res.status(200).json(result.rows);
        
    } catch (err) {
        console.error('Erro ao buscar produtos:', err);
        res.status(500).json({ error: 'Erro interno do servidor' });
    }
});

/**
 * Rota [POST] /api/orders
 * Cria um novo pedido no banco de dados.
 * Isso requer uma TRANSAÇÃO para garantir a integridade dos dados.
 */
app.post('/api/orders', async (req, res) => {
    
    // 1. Pega os dados que o App do Cliente enviou no "corpo" (body) da requisição
    // Exemplo de como o cliente vai enviar:
    // {
    //   "customer_id": 3, (O ID da Maria Cliente)
    //   "delivery_address": "Rua Teste, 456",
    //   "items": [
    //     { "product_id": 1, "quantity": 1 }, // 1 Gás
    //     { "product_id": 2, "quantity": 2 }  // 2 Águas
    //   ]
    // }
    const { customer_id, delivery_address, items } = req.body;

    // Validação básica
    if (!customer_id || !delivery_address || !items || items.length === 0) {
        return res.status(400).json({ error: 'Dados do pedido incompletos.' });
    }

    let client; // Declaramos o cliente fora do try/catch para poder usá-lo no finally

    try {
        // =================================================================
        // INÍCIO DA TRANSAÇÃO
        // =================================================================
        
        // 1. Pega uma conexão do pool
        client = await pool.connect();

        // 2. Inicia a transação
        await client.query('BEGIN');

        // 3. Busca os preços dos produtos para calcular o total
        // (Nunca confie no preço vindo do app do cliente!)
        let totalPrice = 0;
        const productsFromDB = await client.query(
            'SELECT id, price FROM Products WHERE id = ANY($1::int[])',
            [items.map(item => item.product_id)] // [1, 2]
        );

        // Mapeia os preços para um objeto para fácil acesso: { 1: '110.00', 2: '15.00' }
        const priceMap = productsFromDB.rows.reduce((map, product) => {
            map[product.id] = parseFloat(product.price);
            return map;
        }, {});

        // 4. Calcula o preço total e valida os itens
        for (const item of items) {
            if (!priceMap[item.product_id]) {
                throw new Error(`Produto com ID ${item.product_id} não encontrado.`);
            }
            totalPrice += priceMap[item.product_id] * item.quantity;
        }

        // 5. Insere a "capa" do pedido (Orders) e pega o ID do novo pedido
        const orderInsertQuery = `
            INSERT INTO Orders (customer_id, status, delivery_address, total_price)
            VALUES ($1, $2, $3, $4)
            RETURNING id; 
        `; // RETURNING id nos devolve o ID que acabou de ser criado
        
        const orderResult = await client.query(orderInsertQuery, [
            customer_id,
            'Pendente', // Status inicial
            delivery_address,
            totalPrice
        ]);
        
        const newOrderId = orderResult.rows[0].id;

        // 6. Insere os itens do pedido (OrderItems)
        const itemInsertQuery = `
            INSERT INTO OrderItems (order_id, product_id, quantity, unit_price)
            VALUES ($1, $2, $3, $4);
        `;
        
        // Roda um "INSERT" para cada item no carrinho
        for (const item of items) {
            await client.query(itemInsertQuery, [
                newOrderId,
                item.product_id,
                item.quantity,
                priceMap[item.product_id] // O preço que pegamos do banco
            ]);
        }

// 7. Se tudo deu certo até aqui, salva as mudanças
        await client.query('COMMIT');

        // 8. PREPARA OS DADOS DO NOVO PEDIDO PARA EMITIR
        const newOrderData = {
            order_id: newOrderId,
            customer_id: customer_id,
            status: 'Pendente',
            total_price: totalPrice,
            delivery_address: delivery_address,
            items: items // Os itens que o cliente enviou
        };

        // 9. EMITE O EVENTO "TEMPO REAL" PARA A LOJA
        io.emit('new_order_pending', newOrderData);
        console.log(`Socket Event Emit: new_order_pending (ID: ${newOrderId})`);

        // 10. Envia a resposta de sucesso
        res.status(201).json({ 
            message: 'Pedido criado com sucesso!', 
            orderId: newOrderId,
            totalPrice: totalPrice 
        });

    } catch (err) {
        // =================================================================
        // DEU ERRO! DESFAZ TUDO (ROLLBACK)
        // =================================================================
        if (client) {
            await client.query('ROLLBACK'); // Desfaz todas as queries da transação
        }
        console.error('Erro ao criar pedido:', err);
        res.status(500).json({ 
            error: 'Erro interno do servidor ao processar pedido.',
            details: err.message 
        });

    } finally {
        // =================================================================
        // LIBERA A CONEXÃO (SEMPRE)
        // =================================================================
        if (client) {
            client.release(); // Devolve a conexão ao pool
        }
    }
});

/**
 * Rota [GET] /api/orders/pending
 * Busca e retorna todos os pedidos com status 'Pendente'.
 * Será usada pelo Dashboard da Loja ao carregar.
 */
app.get('/api/orders/pending', async (req, res) => {
    try {
        const client = await pool.connect();
        
        // Query para buscar pedidos E os itens de cada pedido
        // Isso é uma query mais avançada!
        const queryText = `
            SELECT 
                o.id AS order_id, 
                o.customer_id, 
                o.status, 
                o.delivery_address, 
                o.total_price, 
                o.created_at,
                u.name AS customer_name,
                (
                    SELECT json_agg(items)
                    FROM (
                        SELECT 
                            oi.quantity, 
                            p.name AS product_name
                        FROM OrderItems oi
                        JOIN Products p ON oi.product_id = p.id
                        WHERE oi.order_id = o.id
                    ) AS items
                ) AS items_list
            FROM Orders o
            JOIN Users u ON o.customer_id = u.id
            WHERE o.status = 'Pendente'
            ORDER BY o.created_at ASC; -- Pedidos mais antigos primeiro
        `;

        const result = await client.query(queryText);
        client.release();
        
        res.status(200).json(result.rows);
        
    } catch (err) {
        console.error('Erro ao buscar pedidos pendentes:', err);
        res.status(500).json({ error: 'Erro interno do servidor' });
    }
});

/**
 * Rota [PATCH] /api/orders/:id/assign
 * Atribui um pedido pendente a um entregador.
 * Usado pelo Dashboard da Loja.
 */
app.patch('/api/orders/:id/assign', async (req, res) => {
    // 1. Pega o ID do pedido da URL (ex: /api/orders/4/assign)
    const { id } = req.params;
    
    // 2. Pega o ID do entregador do corpo da requisição
    // Ex: { "driver_id": 2 }
    const { driver_id } = req.body;

    if (!driver_id) {
        return res.status(400).json({ error: 'ID do entregador é obrigatório.' });
    }

    try {
        const client = await pool.connect();
        
        // 3. Atualiza o pedido no banco
        const updateQuery = `
            UPDATE Orders
            SET 
                driver_id = $1,
                status = 'Aceito' -- Mudamos o status
            WHERE 
                id = $2 
                AND status = 'Pendente' -- Só pode atribuir se estiver pendente
            RETURNING *; -- Retorna o pedido atualizado
        `;
        
        const result = await client.query(updateQuery, [driver_id, id]);
        client.release();

        // 4. Verifica se algo foi realmente atualizado
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Pedido não encontrado ou já atribuído.' });
        }

        const updatedOrder = result.rows[0];

        // 5. EMITE O EVENTO EM TEMPO REAL PARA O ENTREGADOR!
        // Estamos enviando uma mensagem para o "canal privado"
        // do entregador específico (ex: 'driver_room_2')
        const targetRoom = `driver_room_${driver_id}`;
        io.to(targetRoom).emit('new_assignment', updatedOrder);
        
        console.log(`Socket Event Emit: 'new_assignment' para ${targetRoom} (Pedido ID: ${id})`);

        // 6. Envia a resposta de sucesso para a Loja
        res.status(200).json(updatedOrder);

    } catch (err) {
        console.error('Erro ao atribuir pedido:', err);
        res.status(500).json({ error: 'Erro interno do servidor' });
    }
});

/**
 * Rota [PATCH] /api/orders/:id/complete
 * Finaliza um pedido.
 * Usado pelo App do Entregador.
 */
app.patch('/api/orders/:id/complete', async (req, res) => {
    const { id } = req.params;
    let client; // Para a transação

    try {
        // =================================================================
        // TRANSAÇÃO (Precisamos de 2 etapas: atualizar o pedido E o estoque)
        // =================================================================
        client = await pool.connect();
        await client.query('BEGIN');

        // Etapa 1: Atualiza o status do pedido
        const orderUpdateQuery = `
            UPDATE Orders
            SET status = 'Entregue'
            WHERE id = $1 AND status = 'Aceito' -- Só pode completar se foi aceito
            RETURNING id, driver_id;
        `;
        const orderResult = await client.query(orderUpdateQuery, [id]);

        if (orderResult.rows.length === 0) {
            throw new Error('Pedido não encontrado ou não está com status "Aceito".');
        }

        const driverId = orderResult.rows[0].driver_id;

        // Etapa 2: Busca os itens do pedido para dar baixa no estoque
        const itemsQuery = 'SELECT product_id, quantity FROM OrderItems WHERE order_id = $1';
        const itemsResult = await client.query(itemsQuery, [id]);
        const items = itemsResult.rows; // Ex: [{ product_id: 1, quantity: 1 }, { product_id: 2, quantity: 2 }]

        // Etapa 3: Atualiza o DriverStock para CADA item
        const stockUpdateQuery = `
            UPDATE DriverStock
            SET quantity = quantity - $1
            WHERE driver_id = $2 AND product_id = $3;
        `;
        for (const item of items) {
            await client.query(stockUpdateQuery, [
                item.quantity,
                driverId,
                item.product_id
            ]);
            // (Em um app real, verificaríamos se o estoque ficou negativo)
        }
        
        // Etapa 4: Salva tudo
        await client.query('COMMIT');
        
        // 5. EMITE EVENTO PARA A LOJA (dizendo que o pedido sumiu da fila)
        io.emit('order_completed', { order_id: id });
        console.log(`Socket Event Emit: 'order_completed' (Pedido ID: ${id})`);

        res.status(200).json({ message: 'Pedido finalizado com sucesso!' });

    } catch (err) {
        if (client) {
            await client.query('ROLLBACK');
        }
        console.error('Erro ao finalizar pedido:', err);
        res.status(500).json({ error: 'Erro interno do servidor', details: err.message });
    } finally {
        if (client) {
            client.release();
        }
    }
});

// =================================================================
// LÓGICA DO SOCKET.IO (TEMPO REAL)
// =================================================================
io.on('connection', (socket) => {
    console.log('🔌 Um usuário se conectou ao Socket.IO', socket.id);

    socket.on('driver_online', (driverId) => {
        // ... (código existente)
        socket.join(`driver_room_${driverId}`);
    });

    // =================================================================
    // PASSO NOVO: ENTREGADOR ATUALIZA LOCALIZAÇÃO
    // =================================================================
    // O App do Entregador vai emitir este evento a cada 10 segundos
    socket.on('driver_location_update', async (data) => {
        // 'data' esperado: { driver_id: 2, lat: -23.5505, lng: -46.6333 }
        
        if (!data.driver_id || !data.lat || !data.lng) {
            console.warn('Recebida localização incompleta', data);
            return;
        }

        try {
            // 1. Salva a localização no banco de dados
            const insertQuery = `
                INSERT INTO DriverLocations (driver_id, location)
                VALUES ($1, ST_SetSRID(ST_MakePoint($2, $3), 4326));
            `;
            // NOTA: PostGIS usa (Longitude, Latitude)
            await pool.query(insertQuery, [data.driver_id, data.lng, data.lat]);

            // 2. EMITE A LOCALIZAÇÃO PARA A LOJA
            // A Loja estará "ouvindo" este evento para atualizar o mapa
            io.emit('driver_location_changed', {
                driver_id: data.driver_id,
                lat: data.lat,
                lng: data.lng,
                timestamp: new Date()
            });
            
        } catch (err) {
            console.error('Erro ao salvar localização do entregador:', err);
        }
    });

    // Quando o usuário desconectar
    socket.on('disconnect', () => {
        console.log('❌ Usuário desconectado', socket.id);
    });
});

// =================================================================
// INICIA O SERVIDOR (AGORA USANDO O 'server' DO HTTP)
// =================================================================
server.listen(PORT, () => {
    console.log(`🚀 Servidor BeDeli rodando na porta http://localhost:${PORT}`);
    console.log("Pressione CTRL+C para parar o servidor.");
});