--
-- Localization.lua
--
local _, namespace = ...

namespace.Strings = {}
local Strings = namespace.Strings

Strings.L = setmetatable({}, {
    __index = function(t, k)
        return k;
    end
});
local L = Strings.L

local function color(hexARGB, text)
    return "|c" .. hexARGB .. text .. "|r"
end
local function green(text)
    return color("FF00A800", text)
end -- like the "You receive item: [whatever]" messages
local function white(text)
    return color("FFFFFFFF", text)
end
local function red(text)
    return color("FFA00000", text)
end

--
--  default values are enUS (EU (UK) also uses this)
--

-- stack size on "Auction successful:" subject (like "... (20)")
Strings.STACK_SIZE_PATTERN = "%((%d+)%)" -- NEVER NEEDS LOCALIZATION

-- groups
Strings.GROUP_SALES = "Sales"
Strings.GROUP_PURCHASES = "Purchases"
Strings.GROUP_CANCELLED = "Cancelled"
Strings.GROUP_EXPIRED = "Expired"
Strings.GROUP_SYSTEM = "System"
Strings.GROUP_OTHERS = "Others"

-- senders
Strings.SENDER_POSTMASTER = "The Postmaster"
Strings.SENDER_VASHREEN = "Thaumaturge Vashreen"

-- auction subject lines
Strings.AUCTION_SOLD_PREFIX = "Auction successful:"
Strings.AUCTION_WON_PREFIX = "Auction won:"
Strings.AUCTION_EXPIRED_PREFIX = "Auction expired:"
Strings.AUCTION_CANCELLED_PREFIX = "Auction cancelled:"
Strings.AUCTION_OUTBID_PREFIX = "Outbid on "

-- chat message filtering for purchased/expired/cancelled items
-- Strings.RECEIVE_ITEM_PATTERN	= "^You receive item: (.+)%.$"			-- capture ItemName or ItemNamexNN
-- Strings.FMT_PURCHASED_ITEM		= "You purchased %s for %s%s."			-- You purchased Linen Clothx100 for 1s00c each
-- Strings.FMT_PURCHASED_ITEM_FROM	= "You purchased %s for %s%s from %s."	-- You purchased Linen Clothx100 for 1s00c each from Quarq
Strings.FMT_PURCHASED_SINGLE = "You purchased %s for %s"
Strings.FMT_PURCHASED_MULTIPLE = "You purchased %s for %s each"
Strings.FMT_EXPIRED_ITEM = "You receive expired item %s"
Strings.FMT_CANCELLED_ITEM = "You receive cancelled item %s"

-- You receive 85g 49s 90c
-- You receive 285g 37s 50c for [Frostweave Bag]
-- You receive 85g 49s 90c for [Arkhana]x10 at 8g 99s 99c each
Strings.FMT_RECEIVE_MONEY = "You receive %s" -- You receive 85g 49s 90c
Strings.FMT_RECEIVE_MONEY_SINGLE_ITEM = "You receive %s for %s" -- You receive 285g 37s 50c for [Frostweave Bag]
Strings.FMT_RECEIVE_MONEY_MULTI_ITEM = "You receive %s for %s%s at %s each" -- You receive %85g 49s 90c for %[Arkhana]%x10 at %8g 99s 99c% each

--
--  other locales override
--
local LOCALE = GetLocale()
if (LOCALE == "enUS") then -- includes EU (UK) english
    -- nothing here for enUS

elseif (LOCALE == "deDE") then
    L[Strings.GROUP_SALES] = "Der Umsatz"
    L[Strings.GROUP_PURCHASES] = "Käufe"
    L[Strings.GROUP_CANCELLED] = "Abgebrochen"
    L[Strings.GROUP_EXPIRED] = "Abgelaufen"
    L[Strings.GROUP_SYSTEM] = "System"
    L[Strings.GROUP_OTHERS] = "Andere"

    L[Strings.SENDER_POSTMASTER] = "Der Postmeister"
    L[Strings.SENDER_VASHREEN] = "Thaumaturg Vashreen"

    L[Strings.AUCTION_EXPIRED_PREFIX] = "^Auktion abgelaufen"
    L[Strings.AUCTION_OUTBID_PREFIX] = "^Höheres Gebot für"
    L[Strings.AUCTION_CANCELLED_PREFIX] = "^Auktion abgebrochen"
    L[Strings.AUCTION_SOLD_PREFIX] = "^Auktion erfolgreich"
    L[Strings.AUCTION_WON_PREFIX] = "^Auktion gewonnen"

    L[Strings.FMT_PURCHASED_SINGLE] = "Sie haben den Artikel %s für %s gekauft"
    L[Strings.FMT_PURCHASED_MULTIPLE] = "Sie haben den Artikel %s für jeweils %s gekauft"
    L[Strings.FMT_EXPIRED_ITEM] = "Ihr bekommt einen Gegenstand: %s. Auktion abgelaufen."
    L[Strings.FMT_CANCELLED_ITEM] = "Ihr erhaltet den Gegenstand: %s %s. Auktion Abgebrochen."

    L[Strings.FMT_RECEIVE_MONEY] = "Sie erhalten %s"
    L[Strings.FMT_RECEIVE_MONEY_SINGLE_ITEM] = "Sie erhalten %s für %s %s"
    L[Strings.FMT_RECEIVE_MONEY_MULTI_ITEM] = "Sie erhalten %s für %s %s (je %s)"

    L["Open All"] = "Öffne alle"
    L["Collect"] = "Sammeln"
    L["Take Items"] = "Nimm alles"
    L["Loot All"] = "Nimm alles"

    L["GoPost looting stopped"] = "GoPost Plünderungen gestoppt"
    L["Insufficient bag space"] = "Unzureichende Beutelraum"

    L["COD Amount Due:"] = COD .. " Erforderlich:"

elseif (LOCALE == "esES" or LOCALE == "esMX") then
    L[Strings.GROUP_SALES] = "Ventas"
    L[Strings.GROUP_PURCHASES] = "Las compras"
    L[Strings.GROUP_CANCELLED] = "Cancelado"
    L[Strings.GROUP_EXPIRED] = "Muerto"
    L[Strings.GROUP_SYSTEM] = "Sistema"
    L[Strings.GROUP_OTHERS] = "Otros"

    L[Strings.SENDER_POSTMASTER] = "El Jefe de correos"
    L[Strings.SENDER_VASHREEN] = "Taumaturgo Vahsreen"

    L[Strings.AUCTION_EXPIRED_PREFIX] = "^Subasta terminada"
    L[Strings.AUCTION_OUTBID_PREFIX] = "^Puja superada en"
    L[Strings.AUCTION_CANCELLED_PREFIX] = "^Subasta cancelada"
    L[Strings.AUCTION_SOLD_PREFIX] = "^Subasta conseguida"
    L[Strings.AUCTION_WON_PREFIX] = "^Subasta ganada"

    L[Strings.FMT_PURCHASED_SINGLE] = "Usted compró el artículo %s %s por %s"
    L[Strings.FMT_PURCHASED_MULTIPLE] = "Usted compró el artículo %s por %s cada uno"
    L[Strings.FMT_EXPIRED_ITEM] = "Recibes: %s. Expirado subasta."
    L[Strings.FMT_CANCELLED_ITEM] = "Recibes: %s %s. Cancelado subasta."

    L[Strings.FMT_RECEIVE_MONEY] = "Recibes %s"
    L[Strings.FMT_RECEIVE_MONEY_SINGLE_ITEM] = "Recibes %s por %s %s"
    L[Strings.FMT_RECEIVE_MONEY_MULTI_ITEM] = "Recibes %s por %s %s (%s cada uno)"

    L["Open All"] = "Abrir todo"
    L["Collect"] = "Recoger"
    L["Take Items"] = "tome Artículos"
    L["Loot All"] = "Tomalo todo"

    L["GoPost looting stopped"] = "GoPost saqueo se detuvo"
    L["Insufficient bag space"] = "espacio bolsa insuficiente"

    L["COD Amount Due:"] = COD .. " Necesario:"

elseif (LOCALE == "frFR") then
    L[Strings.GROUP_SALES] = "Ventes"
    L[Strings.GROUP_PURCHASES] = "Achats"
    L[Strings.GROUP_CANCELLED] = "Annulé"
    L[Strings.GROUP_EXPIRED] = "Expiré"
    L[Strings.GROUP_SYSTEM] = "Système"
    L[Strings.GROUP_OTHERS] = "Autres"

    L[Strings.SENDER_POSTMASTER] = "Le maître de poste"
    L[Strings.SENDER_VASHREEN] = "Thaumaturge Vashreen"

    L[Strings.AUCTION_EXPIRED_PREFIX] = "^Vente aux enchères terminée"
    L[Strings.AUCTION_OUTBID_PREFIX] = "^Augmenter l'offre pour"
    L[Strings.AUCTION_CANCELLED_PREFIX] = "^Vente annulée"
    L[Strings.AUCTION_SOLD_PREFIX] = "^Vente aux enchères réussie"
    L[Strings.AUCTION_WON_PREFIX] = "^Vente gagnée"

    L[Strings.FMT_PURCHASED_SINGLE] = "Vous avez acheté %s %s à %s"
    L[Strings.FMT_PURCHASED_MULTIPLE] = "Vous avez acheté %s à %s pièce"
    L[Strings.FMT_EXPIRED_ITEM] = "Vous recevez l'objet : %s. Vente aux enchères Expiré."
    L[Strings.FMT_CANCELLED_ITEM] = "Vous recevez l'objet : %s %s. Vente aux enchères annulée."

    L[Strings.FMT_RECEIVE_MONEY] = "Vous recevez %s"
    L[Strings.FMT_RECEIVE_MONEY_SINGLE_ITEM] = "Vous recevez %s pour %s %s"
    L[Strings.FMT_RECEIVE_MONEY_MULTI_ITEM] = "Vous recevez %s pour %s %s (%s chacun)"

    L["Open All"] = "Ouvre tout"
    L["Collect"] = "Collecte"
    L["Take Items"] = "prenez Articles"
    L["Loot All"] = "Prendre toutes"

    L["GoPost looting stopped"] = "GoPost pillage arrêté"
    L["Insufficient bag space"] = "Espace insuffisant de sac"

    L["COD Amount Due:"] = COD .. " Champs obligatoires:"

elseif (LOCALE == "itIT") then
    L[Strings.GROUP_SALES] = "I saldi"
    L[Strings.GROUP_PURCHASES] = "acquisti"
    L[Strings.GROUP_CANCELLED] = "Annullato"
    L[Strings.GROUP_EXPIRED] = "Scaduto"
    L[Strings.GROUP_SYSTEM] = "Sistema"
    L[Strings.GROUP_OTHERS] = "Altri"

    L[Strings.SENDER_POSTMASTER] = "Il Postino"
    L[Strings.SENDER_VASHREEN] = "Taumaturgo Vashreen"

    L[Strings.AUCTION_EXPIRED_PREFIX] = "^Asta scaduta"
    L[Strings.AUCTION_OUTBID_PREFIX] = "^Hanno rilanciato per"
    L[Strings.AUCTION_CANCELLED_PREFIX] = "^Asta annullata"
    L[Strings.AUCTION_SOLD_PREFIX] = "^Asta riuscita"
    L[Strings.AUCTION_WON_PREFIX] = "^Asta vinta"

    L[Strings.FMT_PURCHASED_SINGLE] = "Hai comprato %s %s per %s"
    L[Strings.FMT_PURCHASED_MULTIPLE] = "Hai comprato %s per %s ciascuno"
    L[Strings.FMT_EXPIRED_ITEM] = "Hai ricevuto: %s. scaduto Asta."
    L[Strings.FMT_CANCELLED_ITEM] = "Hai ricevuto: %s %s. Asta Annullato."

    L[Strings.FMT_RECEIVE_MONEY] = "Ricevi %s"
    L[Strings.FMT_RECEIVE_MONEY_SINGLE_ITEM] = "Ricevi %s per %s %s"
    L[Strings.FMT_RECEIVE_MONEY_MULTI_ITEM] = "Ricevi %s per %s %s (%s ciascuno)"

    L["Open All"] = "aperto tutto"
    L["Collect"] = "Raccogliere"
    L["Take Items"] = "prendere Articoli"
    L["Loot All"] = "Prendi tutto"

    L["GoPost looting stopped"] = "GoPost saccheggi fermato"
    L["Insufficient bag space"] = "spazio bag insufficiente"

    L["COD Amount Due:"] = COD .. " necessario:"

elseif (LOCALE == "koKR") then
    L[Strings.GROUP_SALES] = "매상"
    L[Strings.GROUP_PURCHASES] = "구매"
    L[Strings.GROUP_CANCELLED] = "취소 된"
    L[Strings.GROUP_EXPIRED] = "만료"
    L[Strings.GROUP_SYSTEM] = "체계"
    L[Strings.GROUP_OTHERS] = "기타"

    L[Strings.SENDER_POSTMASTER] = "우체국장"
    L[Strings.SENDER_VASHREEN] = "마력술사 바시린"

    L[Strings.AUCTION_EXPIRED_PREFIX] = "^경매 만료"
    L[Strings.AUCTION_OUTBID_PREFIX] = "^입찰금 반환"
    L[Strings.AUCTION_CANCELLED_PREFIX] = "^경매 취소"
    L[Strings.AUCTION_SOLD_PREFIX] = "^경매 낙찰"
    L[Strings.AUCTION_WON_PREFIX] = "^경매 낙찰"

    L[Strings.FMT_PURCHASED_SINGLE] = "나는 %s %s를 사서 %s를 보냈다"
    L[Strings.FMT_PURCHASED_MULTIPLE] = "당신은 %s를 구입하고 각각 %s를 보냈습니다"
    L[Strings.FMT_EXPIRED_ITEM] = "아이템을 획득했습니다: %s 경매 만료."
    L[Strings.FMT_CANCELLED_ITEM] = "아이템을 획득했습니다: %s %s 경매 취소."

    L[Strings.FMT_RECEIVE_MONEY] = "%s받습니다."
    L[Strings.FMT_RECEIVE_MONEY_SINGLE_ITEM] = "%s을 받음 : %s %s를 판매 함"
    L[Strings.FMT_RECEIVE_MONEY_MULTI_ITEM] = "%s을 받음 : %s %s를 판매 함 (각 %s)"

    L["Open All"] = "열기 모든"
    L["Collect"] = "수집"
    L["Take Items"] = "항목을 가지고"
    L["Loot All"] = "다 가져 가라"

    L["GoPost looting stopped"] = "GoPost 중지 약탈"
    L["Insufficient bag space"] = "부족 가방 공간"

    L["COD Amount Due:"] = COD .. " 필수:"

elseif (LOCALE == "ptBR") then
    L[Strings.GROUP_SALES] = "Vendas"
    L[Strings.GROUP_PURCHASES] = "compras"
    L[Strings.GROUP_CANCELLED] = "Cancelado"
    L[Strings.GROUP_EXPIRED] = "Expirado"
    L[Strings.GROUP_SYSTEM] = "Sistema"
    L[Strings.GROUP_OTHERS] = "Outras"

    L[Strings.SENDER_POSTMASTER] = "O Chefe do Correio"
    L[Strings.SENDER_VASHREEN] = "Taumaturgo Vashreen"

    L[Strings.AUCTION_EXPIRED_PREFIX] = "^Leilão expirado"
    L[Strings.AUCTION_OUTBID_PREFIX] = "^Lance coberto em"
    L[Strings.AUCTION_CANCELLED_PREFIX] = "^Leilão cancelado"
    L[Strings.AUCTION_SOLD_PREFIX] = "^Leilão bem-sucedido"
    L[Strings.AUCTION_WON_PREFIX] = "^Leilão ganho"

    L[Strings.FMT_PURCHASED_SINGLE] = "Você comprou a %s %s por %s"
    L[Strings.FMT_PURCHASED_MULTIPLE] = "Você comprou a %s por %s cada"
    L[Strings.FMT_EXPIRED_ITEM] = "Você recebe o item: %s. leilão Expired."
    L[Strings.FMT_CANCELLED_ITEM] = "Você recebe o item: %s %s. leilão cancelado."

    L[Strings.FMT_RECEIVE_MONEY] = "Você recebe %s"
    L[Strings.FMT_RECEIVE_MONEY_SINGLE_ITEM] = "Você recebe %s para %s %s"
    L[Strings.FMT_RECEIVE_MONEY_MULTI_ITEM] = "Você recebe %s para %s %s (%s cada)"

    L["Open All"] = "Abra tudo"
    L["Collect"] = "coletar"
    L["Take Items"] = "tome Itens"
    L["Loot All"] = "Leve tudo"

    L["GoPost looting stopped"] = "GoPost saques parou"
    L["Insufficient bag space"] = "espaço do saco insuficiente"

    L["COD Amount Due:"] = COD .. " Requeridos:"

elseif (LOCALE == "ruRU") then
    L[Strings.GROUP_SALES] = "Продажи"
    L[Strings.GROUP_PURCHASES] = "Покупки"
    L[Strings.GROUP_CANCELLED] = "отменен"
    L[Strings.GROUP_EXPIRED] = "Истекший"
    L[Strings.GROUP_SYSTEM] = "система"
    L[Strings.GROUP_OTHERS] = "другие"

    L[Strings.SENDER_POSTMASTER] = "Почтальон"
    L[Strings.SENDER_VASHREEN] = "Чудотворец Вашрин"

    L[Strings.AUCTION_EXPIRED_PREFIX] = "^Аукцион не состоялся"
    L[Strings.AUCTION_OUTBID_PREFIX] = "^Ваша ставка перебита"
    L[Strings.AUCTION_CANCELLED_PREFIX] = "^Аукцион отменен"
    L[Strings.AUCTION_SOLD_PREFIX] = "^Аукцион состоялся"
    L[Strings.AUCTION_WON_PREFIX] = "^Вы выиграли торги"

    L[Strings.FMT_PURCHASED_SINGLE] = "Вы купили %s %s за %s"
    L[Strings.FMT_PURCHASED_MULTIPLE] = "Вы купили %s за %s каждый"
    L[Strings.FMT_EXPIRED_ITEM] = "Вы получаете предмет: %s. Аукцион Expired."
    L[Strings.FMT_CANCELLED_ITEM] = "Вы получаете предмет: %s %s. Аукцион Отменено."

    L[Strings.FMT_RECEIVE_MONEY] = "Вы получаете %s"
    L[Strings.FMT_RECEIVE_MONEY_SINGLE_ITEM] = "Вы получаете %s за %s %s"
    L[Strings.FMT_RECEIVE_MONEY_MULTI_ITEM] = "Вы получаете %s за %s %s (%s каждый)"

    L["Open All"] = "Открыть все"
    L["Collect"] = "собирать"
    L["Take Items"] = "Взять все"
    L["Loot All"] = "Взять все"

    L["GoPost looting stopped"] = "GoPost мародерство остановился"
    L["Insufficient bag space"] = "Недостаточный мешок пространства"

    L["COD Amount Due:"] = COD .. " необходимые:"

elseif (LOCALE == "zhCN") then
    L[Strings.GROUP_SALES] = "销售"
    L[Strings.GROUP_PURCHASES] = "购买"
    L[Strings.GROUP_CANCELLED] = "取消"
    L[Strings.GROUP_EXPIRED] = "过期"
    L[Strings.GROUP_SYSTEM] = "系统"
    L[Strings.GROUP_OTHERS] = "其他"

    L[Strings.SENDER_POSTMASTER] = "邮政长"
    L[Strings.SENDER_VASHREEN] = "魔术师瓦西里恩"

    L[Strings.AUCTION_EXPIRED_PREFIX] = "^拍卖已到期"
    L[Strings.AUCTION_OUTBID_PREFIX] = "^竞标.+失败"
    L[Strings.AUCTION_CANCELLED_PREFIX] = "^拍卖取消"
    L[Strings.AUCTION_SOLD_PREFIX] = "^拍卖成功"
    L[Strings.AUCTION_WON_PREFIX] = "^竞拍获胜"

    L[Strings.FMT_PURCHASED_SINGLE] = "你买了%s %s并花了%s"
    L[Strings.FMT_PURCHASED_MULTIPLE] = "你买了%s每个%s"
    L[Strings.FMT_EXPIRED_ITEM] = "你获得了物品：%s。 拍卖过期."
    L[Strings.FMT_CANCELLED_ITEM] = "你获得了：%s %s。 拍卖取消."

    L[Strings.FMT_RECEIVE_MONEY] = "您收到%s"
    L[Strings.FMT_RECEIVE_MONEY_SINGLE_ITEM] = "您收到%s：已售出%s %s"
    L[Strings.FMT_RECEIVE_MONEY_MULTI_ITEM] = "您收到%s：已售出%s %s（每个%s）"

    L["Open All"] = "打开所有"
    L["Collect"] = "搜集"
    L["Take Items"] = "以项目"
    L["Loot All"] = "通吃"

    L["GoPost looting stopped"] = "GoPost停止掠夺"
    L["Insufficient bag space"] = "没有足够的背包空间"

    L["COD Amount Due:"] = COD .. " 需要:"

elseif (LOCALE == "zhTW") then
    L[Strings.GROUP_SALES] = "銷售"
    L[Strings.GROUP_PURCHASES] = "購買"
    L[Strings.GROUP_CANCELLED] = "取消"
    L[Strings.GROUP_EXPIRED] = "過期"
    L[Strings.GROUP_SYSTEM] = "系統"
    L[Strings.GROUP_OTHERS] = "其他"

    L[Strings.SENDER_POSTMASTER] = "邮政长"
    L[Strings.SENDER_VASHREEN] = "魔术师瓦西里恩"

    L[Strings.AUCTION_EXPIRED_PREFIX] = "^拍賣已到期"
    L[Strings.AUCTION_OUTBID_PREFIX] = "^競標.+失敗"
    L[Strings.AUCTION_CANCELLED_PREFIX] = "^拍賣取消"
    L[Strings.AUCTION_SOLD_PREFIX] = "^拍賣成功"
    L[Strings.AUCTION_WON_PREFIX] = "^競拍獲勝"

    L[Strings.FMT_PURCHASED_SINGLE] = "你買了%s %s並花了%s"
    L[Strings.FMT_PURCHASED_MULTIPLE] = "你買了%s每個%s"
    L[Strings.FMT_EXPIRED_ITEM] = "你獲得了物品:%s。 拍賣過期."
    L[Strings.FMT_CANCELLED_ITEM] = "你獲得物品:%s %s。 拍賣取消."

    L[Strings.FMT_RECEIVE_MONEY] = "您收到%s"
    L[Strings.FMT_RECEIVE_MONEY_SINGLE_ITEM] = "您收到%s：已售出%s %s"
    L[Strings.FMT_RECEIVE_MONEY_MULTI_ITEM] = "您收到%s：已售出%s %s（每個%s）"

    L["Open All"] = "打開所有"
    L["Collect"] = "蒐集"
    L["Take Items"] = "以項目"
    L["Loot All"] = "通吃"

    L["GoPost looting stopped"] = "GoPost停止掠奪"
    L["Insufficient bag space"] = "沒有足夠的背包空間"

    L["COD Amount Due:"] = COD .. " 需要:"

end

