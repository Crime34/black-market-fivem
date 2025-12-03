let currentCategory = 'all';
let currentItem = null;
let playerMoney = 50000;
let isInFiveM = false;

function checkFiveM() {
    try {
        if (window.location.protocol === 'https:' && window.location.hostname.includes('cfx-nui')) {
            isInFiveM = true;
        }
    } catch (e) {
        isInFiveM = false;
    }
}

function postToNUI(event, data) {
    if (!isInFiveM) {
        console.log('[DEV] Would send to NUI:', event, data);
        return Promise.resolve();
    }
    
    return fetch(`https://${GetParentResourceName()}/${event}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
    }).catch(err => {
        console.error('NUI Error:', err);
    });
}

const blackMarketItems = [
    {
        id: 1,
        name: "lockpick",
        label: "Crochet",
        price: 150,
        description: "Permet de crocheter les portes des véhicules",
        category: "tools",
        icon: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSp3El6GwvkqawtemS67PEBs7UxWqfZii7ceA&s"
    },
    {
        id: 2,
        name: "weapon_snspistol",
        label: "Pétoire",
        price: 5000,
        description: "Arme de poing standard",
        category: "weapons",
        icon: "https://www.grandtheftauto5.fr/images/armes/hd/pi-petoire.png"
    },
    {
        id: 3,
        name: "weapon_combatpistol",
        label: "Pistolet de Combat",
        price: 7500,
        description: "Pistolet de combat amélioré",
        category: "weapons",
        icon: "https://r2.fivemanage.com/0xt2DTcWZJCXWv87cnhVh/pistolet-tanfoglio-combat-cal-9mm-removebg-preview.png"
    },
    {
        id: 4,
        name: "ammo",
        label: "Chargeur",
        price: 50,
        description: "Chargeur pour arme",
        category: "ammo",
        icon: "https://www.mypubg.fr/wp-content/uploads/2017/08/Chargeur-haute-capacit%C3%A9-pour-pistolet-Magazine_Extended_Small.png"
    },
    {
        id: 5,
        name: "weapon_microsmg",
        label: "Micro SMG",
        price: 12000,
        description: "Mitraillette compacte",
        category: "weapons",
        icon: "https://r2.fivemanage.com/0xt2DTcWZJCXWv87cnhVh/micro-smg.png"
    },
    {
        id: 6,
        name: "drill",
        label: "Perceuse",
        price: 500,
        description: "Outil pour percer les coffres",
        category: "tools",
        icon: "https://r2.fivemanage.com/0xt2DTcWZJCXWv87cnhVh/gta-5-braquages-5-removebg-preview.png"
    },
    {
        id: 7,
        name: "hackerdevice",
        label: "Dispositif de Hack",
        price: 1000,
        description: "Pour hacker les systèmes électroniques",
        category: "tools",
        icon: "https://r2.fivemanage.com/0xt2DTcWZJCXWv87cnhVh/make-you-an-usb-gta-5-mod-menu-on-and-ship-you-it-removebg-preview.png"
    },
    {
        id: 8,
        name: "armor",
        label: "Gilet Pare-Balles",
        price: 800,
        description: "Protection corporelle",
        category: "protection",
        icon: "https://r2.fivemanage.com/0xt2DTcWZJCXWv87cnhVh/gpb-iiia-full-tactical-removebg-preview.png"
    }
];

document.addEventListener('DOMContentLoaded', () => {
    checkFiveM();
    setupEventListeners();
    updateMoneyDisplay();
    renderItems();
});

function setupEventListeners() {
    document.getElementById('close-btn').addEventListener('click', closeMarket);
    
    document.querySelectorAll('.category-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            currentCategory = e.target.dataset.category;
            
            document.querySelectorAll('.category-btn').forEach(b => b.classList.remove('active'));
            e.target.classList.add('active');
            
            renderItems();
        });
    });
    
    document.getElementById('modal-close').addEventListener('click', closeModal);
    document.getElementById('btn-cancel').addEventListener('click', closeModal);
    document.getElementById('btn-confirm').addEventListener('click', confirmPurchase);
    
    document.getElementById('qty-minus').addEventListener('click', () => changeQuantity(-1));
    document.getElementById('qty-plus').addEventListener('click', () => changeQuantity(1));
    document.getElementById('quantity-input').addEventListener('input', updateTotalPrice);
    
    document.addEventListener('keyup', (e) => {
        if (e.key === 'Escape') {
            closeModal();
            closeMarket();
        }
    });
}

function renderItems() {
    const grid = document.getElementById('items-grid');
    grid.innerHTML = '';
    
    const filteredItems = currentCategory === 'all' 
        ? blackMarketItems 
        : blackMarketItems.filter(item => item.category === currentCategory);
    
    filteredItems.forEach(item => {
        const card = createItemCard(item);
        grid.appendChild(card);
    });
}

function createItemCard(item) {
    const card = document.createElement('div');
    card.className = 'item-card';
    card.innerHTML = `
        <div class="item-image">
            <img src="${item.icon}" alt="${item.label}" onerror="this.style.display='none'">
        </div>
        <div class="item-name">${item.label}</div>
        <div class="item-description">${item.description}</div>
        <div class="item-price">${item.price.toLocaleString()}</div>
    `;
    
    card.addEventListener('click', () => openBuyModal(item));
    
    return card;
}

function openBuyModal(item) {
    currentItem = item;
    
    console.log('[Black Market UI] Modal ouvert pour:', item.name, '(' + item.label + ')');
    
    document.getElementById('modal-title').textContent = `Acheter ${item.label}`;
    document.getElementById('modal-image').innerHTML = `<img src="${item.icon}" alt="${item.label}" style="width: 80%; height: 80%; object-fit: contain;" onerror="this.style.display='none'">`;
    document.getElementById('modal-description').textContent = item.description;
    document.getElementById('modal-price').textContent = `${item.price.toLocaleString()}`;
    document.getElementById('quantity-input').value = 1;
    
    updateTotalPrice();
    
    document.getElementById('buy-modal').classList.remove('hidden');
}

function closeModal() {
    document.getElementById('buy-modal').classList.add('hidden');
    currentItem = null;
}

function changeQuantity(delta) {
    const input = document.getElementById('quantity-input');
    let value = parseInt(input.value) || 1;
    value = Math.max(1, Math.min(100, value + delta));
    input.value = value;
    updateTotalPrice();
}

function updateTotalPrice() {
    if (!currentItem) return;
    
    const quantity = parseInt(document.getElementById('quantity-input').value) || 1;
    const total = currentItem.price * quantity;
    
    document.getElementById('total-price').textContent = `$${total.toLocaleString()}`;
}

function confirmPurchase() {
    if (!currentItem) return;
    
    const quantity = parseInt(document.getElementById('quantity-input').value) || 1;
    const total = currentItem.price * quantity;
    
    console.log('[Black Market UI] Achat confirmé:', {
        name: currentItem.name,
        label: currentItem.label,
        quantity: quantity,
        price: total
    });
    
    postToNUI('buyItem', {
        item: currentItem.name,
        quantity: quantity,
        price: total
    });
    
    closeModal();
}

function updateMoneyDisplay() {
    document.getElementById('player-money').textContent = `$${playerMoney.toLocaleString()}`;
}

function closeMarket() {
    const container = document.getElementById('blackmarket-container');
    if (container) {
        container.classList.add('hidden');
    }
    
    postToNUI('close', {});
}

window.addEventListener('message', (event) => {
    const data = event.data;
    
    switch(data.action) {
        case 'openMarket':
            const container = document.getElementById('blackmarket-container');
            if (container) {
                container.classList.remove('hidden');
                container.style.display = 'flex';
            }
            
            if (data.money !== undefined) {
                playerMoney = data.money;
                updateMoneyDisplay();
            }
            if (data.items) {
                blackMarketItems.length = 0;
                blackMarketItems.push(...data.items);
                renderItems();
            }
            console.log('[Black Market UI] Marché ouvert - Argent: $' + playerMoney);
            break;
            
        case 'closeMarket':
            const cont = document.getElementById('blackmarket-container');
            if (cont) {
                cont.classList.add('hidden');
                cont.style.display = 'none';
            }
            closeModal();
            console.log('[Black Market UI] Marché fermé');
            break;
            
        case 'updateMoney':
            playerMoney = data.money;
            updateMoneyDisplay();
            console.log('[Black Market UI] Argent mis à jour: $' + playerMoney);
            break;
    }
});

function GetParentResourceName() {
    if (!isInFiveM) {
        return 'black_market_crime';
    }
    
    let resource = 'black_market_crime';
    
    try {
        if (window.location.href.includes('://nui-')) {
            const match = window.location.href.match(/nui-(.+?)\//);
            if (match && match[1]) {
                resource = match[1];
            }
        }
    } catch (e) {
        console.log('Could not get resource name');
    }
    
    return resource;
}