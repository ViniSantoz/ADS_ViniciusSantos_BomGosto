const { onRequest } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { defineSecret } = require('firebase-functions/params');

initializeApp();
const db = getFirestore();

// Configurar no terminal com: firebase functions:secrets:set ASAAS_WEBHOOK_TOKEN
const ASAAS_WEBHOOK_TOKEN = defineSecret('ASAAS_WEBHOOK_TOKEN');

exports.asaasWebhook = onRequest(
  { secrets: [ASAAS_WEBHOOK_TOKEN], region: 'southamerica-east1' },
  async (req, res) => {
    try {
      // 1. Validar o token de segurança enviado pelo Asaas
      const tokenRecebido = req.header('asaas-access-token');
      if (tokenRecebido !== ASAAS_WEBHOOK_TOKEN.value()) {
        console.warn('Tentativa de acesso com token inválido.');
        res.status(401).send('Token inválido');
        return;
      }

      const { event, payment } = req.body;

      if (!payment || !payment.id) {
        res.status(400).send('Payload inválido');
        return;
      }

      // 2. Recuperar o ID do pedido que salvamos no externalReference no Flutter
      const pedidoId = payment.externalReference;

      if (!pedidoId) {
        console.log(`Pagamento ${payment.id} recebido sem externalReference (pedidoId). Ignorando.`);
        res.status(200).json({ received: true, reason: 'Sem referência do Firestore' });
        return;
      }

      // Referência direta ao documento do pedido que o app do cliente está escutando
      const pedidoRef = db.collection('pedidos').doc(pedidoId);

      // 3. Mapear os eventos do Asaas para as regras de negócio do Bom Gosto
      switch (event) {
        case 'PAYMENT_RECEIVED':
        case 'PAYMENT_CONFIRMED':
          // Altera o status para 'Aprovado' (exatamente o que o StreamBuilder espera no app)
          await pedidoRef.set(
            {
              status: 'Aprovado', 
              asaasPaymentId: payment.id,
              pagoEm: new Date().toISOString(),
            },
            { merge: true },
          );
          console.log(`Pedido ${pedidoId} ATUALIZADO PARA APROVADO via Webhook.`);
          break;

        case 'PAYMENT_OVERDUE':
          await pedidoRef.set({ status: 'Vencido' }, { merge: true });
          break;

        case 'PAYMENT_DELETED':
          await pedidoRef.set({ status: 'Cancelado' }, { merge: true });
          break;

        default:
          console.log(`Evento recebido mas não modificado no pedido: ${event}`);
      }

      // Retorno obrigatório em menos de 5 segundos para o Asaas não reenviar o mesmo POST
      res.status(200).json({ success: true });

    } catch (error) {
      console.error('Erro crítico no processamento do webhook:', error);
      res.status(500).send('Erro interno do servidor');
    }
  },
);