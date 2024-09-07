-- Скрипт для робота, для поднятия характеристик у растений или разведения гибридов
-- Автор программы: slprime весна 2021
-- Автор идеи: aka_zaratustra осень 2020
local ver = "2.2.28" -- версия программы
-- Историю версий см. в конце файла

-- 0. Tермины
-- 0.1. `целевыe культурами/растения` - растение которое хочешь размножить/поднять статы
-- 0.2. `гибриды` - другой вид растения, что получается при скрещивании целевого растения

-- 1. Робот
-- 1.1. У робота должны в обязательном порядке присутствовать компоненты: Geolyzer, Inventory Upgrade, Inventory Controller Upgrade
-- 1.2. Если вы играете на публичном сервере тогда нужен ещё и Internet Card для простого способа залить программу
-- 1.3. Рекомендуется для удобства поместить файл с этим скриптом в папку /home/
-- Имя файла скрипта с настройками добавить в файл /home/.shrc - тогда скрипт будет запускаться при включении робота автоматически
-- Example: crop_stats --x=3 --y=9 --h=y --target=rape --resistance=12
-- P.S. Inventory Upgrage никогда не бывает много )
-- P.S. Используйте 2 x 1.5. RAM или больше

-- 2. Схема поля и сундуков (postimg.cc/gallery/wzxnmdJ - но тут неверная высота поля) (postimg.cc/gallery/pxzpbcj - тут всё ок)
-----------------                              ------------------------
-- схема грядки -
-- |1X|2X|3X|..|XX
-- |..|..|..|..|..
-- |14|24|34|..|X4
-- |13|23|33|..|X3
-- |12|22|32|..|X2							   R2|R1|
-- |11|21|31|..|X1								 |R0|
-----------------								 |  |11|12|13|14|..|1X
-- |L0|L1|P0|R1|R0								 |  |
-- |--|L2|GG|R2|--								 |
-----------------                              ------------------------

-- L0 - сундук, куда будут помещаться гибриды (сундук не обязателен)
-- L1 - сундук, куда будут помещаться мешочки с целевыми культурами. Если перед стартом разместить туда другие семена, то они также будут посажены если на поле есть свободное место
-- L2 - сундук, куда будут помещаться урожай (сундук не обязателен)
-- R0 - Фильтр для семян. 1. Семена - чёрный список. 2. Бумага переименованная на наковальне - белый список (сундук не обязателен)
-- R1 - сундук с палками, водой, удобрениями, киркой, рудой под растения и weed-ex
-- R2 - сундук для мусора, куда будут помещаться негодное растение, целевые семена низкого качества а также сорняки. Можно использовать void chest из RailCraft, trash can из Extra Utilities
-- GG - робот должен стоять тут. Эта точка - центр поля

-- 2.1. Изначальный параметры поля:
-- 2.1.1. размер поля = 7x7
-- 2.1.2. growth = 22
-- 2.1.3. gain = 31
-- 2.1.4. resistance = чем меньше. Его робот не поднимает, а при возможности опускает до 0
-- P.S. Сундук L0 и R0 находится под L1 и R1 соответственно
-- P.S. Растения с характеристикой growth = 24 и выше считается сорняком

-- 3. Старт робота:
-- 3.1. У робота в активном слоте должна лежать лопатка (spade)
-- 3.2. У робота должно быть как минимум 2 мешочка. Этого можно добиться высадив семена на нечётные ячейки (x + y должно быть нечётным). Желательно на |12| и |14| или поместить в сундук L1
-- 3.3. Робот начинает, смотря мордочкой в сторону поля на координате z на 1 больше, чем координата z у кропсов. Добиться этого можно, если поставить блок под точку GG и установить робота на нем, смотря в сторону поля

-- 4. Работа с рудой
-- 4.1. если в робота или в R1 поставить кирку робот начнёт работать с рудой
-- 4.2. Высота поля должна составлять 3 блока земли и 2 блока воздуха
-- 4.3. Туннель должен проходить в позиции P0
-- 4.4. Руду нужно помещать в сундук R1
-- P.S. Обязательно должно встречаться слово pickaxe в названии кирки

-- 5. Расширенные настройки робота:
-- Робота можно настроить либо через параметры командной строки при старте скрипта, либо через предмет "бумага", переименованный на наковальне, либо через редактирование этого скрипта
-- 5.1. Ширина поля:
-- 5.1.1. name: `width` или `x`
-- 5.1.2. default: 7
-- 5.1.3. min: 3
-- 5.1.4. P.S. значение должно быть нечётным
-- 5.1.5. P.S. х=1 также будет работать. Т.к. точка GG - это центр поля, запуск робота с х=1 задает поле в виде полосы шириной в 1 блок, проходящее по оси между сундуками.
-- 5.1.6. Examples: args: `--width=7`, `--x=7`; paper: `args: width=7`, `args: x=7`

-- 5.2. Высота поля:
-- 5.2.1. name: `height` или `y`
-- 5.2.2. default: 7
-- 5.2.3. min: 3
-- 5.2.4. P.S. значение должно быть нечётным
-- 5.2.5. Examples: args: `--height=7`, `--y=7`; paper: `args: height=7`, `args: y=7`

-- 5.3. Целевое растения:
-- 5.3.1. name: `target` или `t`
-- 5.3.2. default: nil
-- 5.3.3. P.S. регист не имеет значения
-- 5.3.4. Examples: args: `--target=ferru`, `--target="ardite berry"`; paper: `args: target=ferru`, `args: target="ardite berry"`

-- 5.4. Гибриды:
-- 5.4.1. name: `hybrid` или `h`
-- 5.4.2. default: 4
-- 5.4.3. value: yes|on|y - собирать все гибриды
-- 5.4.4. value: no|off|n - уничтожать гибриды
-- 5.4.4. value: `number` - число гибридов что нужно сохранять. min = 0, max=100
-- 5.4.5. Examples: args: `--hybrid=4`, `--h=4`; paper: `args: hybrid=4`, `args: h=4`

-- 5.5. Growth:
-- 5.5.1. name: `growth`
-- 5.5.2. default: 22
-- 5.5.3. max: 23
-- 5.5.4. info: указывает МИНимальное значение стата
-- 5.5.5. Examples: args: `--growth=22`; paper: `args: growth=22`

-- 5.6. Gain:
-- 5.6.1. name: `gain`
-- 5.6.2. default: 31
-- 5.6.3. max: 31
-- 5.6.4. info: указывает МИНимальное значение стата
-- 5.6.5. Examples: args: `--gain=31`; paper: `args: gain=31`

-- 5.7. Resistance:
-- 5.7.1. name: `resistance`
-- 5.7.2. default: 4
-- 5.7.3. max: 31
-- 5.7.4. info: указывает МАКСимальное значение стата
-- 5.7.5. Examples: args: `--resistance=4`; paper: `args: resistance=4`

-- 5.7. Shutdown:
-- 5.7.1. name: `shutdown`
-- 5.7.2. default: true
-- 5.7.3. value: yes|y|true - при ошибке робот ждет 10 секунд и отключается
-- 5.7.4. value: no|n|false - при ошибке робот дает доступ в терминал и ждет до тех пор, пока не разрядится
-- 5.7.5. info: false поможет в первичной настройке, решая следующую проблему: если робот отключается, доступ к клавиатуре теряется + логи стираются, если робот не был подключен к зарядке на момент выключения
-- 5.7.6. Examples: args: `--shutdown=yes`; paper: `args: shutdown=yes`

-- 6. P.S.
-- 6.1. Установить скрипт: `pastebin get 44GreerS -f crop_stats.lua`
-- 6.2. Запустить скрипт с параметрами: `crop_stats --x=11 --y=11 --h=4`
-- 6.3. Запустить скрипт с бумажкой в инвентаре у робота: `args: x=11 y=11 h=4`. Бумагу поместить в робота перед стартом скрипта
-- 6.4. Остановить робота можно поместив в робота бумажку с надписью `cmd: shutdown` (без ковычек)
-- 6.7. Сказать роботу чтобы он очистил поле можно поместив в робота бумажку с надписью `cmd: cleanup` (без ковычек)
-- 6.7. Пересобрать черный и белый список `cmd: refresh filter` (без ковычек)
-- 6.8. Любая ошибка на роботе приводит к его остановке. Требуется возврат на исходную позицию и перезапуск.
-- 6.9. Если остались вопросы, смотрите обзор на скрипт. Демонстрация: youtu.be/0r70ZG7zOYw

-- 7. Занимательные факты
-- 7.1. Перед работой робот обходит поле сбивая только сорняк.
-- 7.2. Если инвентарь робота переполнен, он идёт на базу для её очистки и после возвращается на место где остановился и продолжает
-- 7.3. Если у робота начинает заканчиваться энергия он возвращается на подзарядку и после возвращается на место где остановился и продолжает
-- 7.4. Если у робота закончились палки он возвращается на подзарядку и после возвращается на место где остановился и продолжает
-- 7.5. Робот после сбора растения сбивает и палки т.к. если их не сбить он больше не сможет получить с этой грядки семян (
-- 7.6. Weed-ex используется только на пустые палки. На скорость это не влияет, проверено
-- 7.7. Если в бочке кончаются жёрдочки(палки) или энергия, робот сломает пустые палки, если они есть на поле и завершит свою работу с ошибкой (чтобы всё поле не сожрали сорняки)
-- 7.8. Если выращиваете быстро растущие растения желательно дать роботу weed-ex. Не стоит его давать crop-matron-у. Он его не правильно использует
-- 7.9. Чтобы выращивать рудные растения достаточно одного блока. Чем больше блоков тем быстрее процесс, но с одним тоже работает
-- 7.10. Сундук L1 желательно брать поменьше т.к. там после работы останутся только целевые растения, а с большим сундуком робот будет долго тупить
-- 7.11. Если робот не может выбросить в сундук предмет - он сбивает двойные жёрдочки и останавливается с ошибкой
-- 7.12. После удачного окончания работы или ошибки робот вернётся на рабочее место и выключится. Ошибку можно будет прочесть в файле `crop_stats.log`
-- 7.13. Из L1 не стоит забирать семена до завершения работы
-- 7.14. После того как L1 заполняется на 90% робот его отсортирует удаляя плохие растения пока не останутся там только целевые характеристики
-- 7.15. Как только L1 полностью заполнится семенами с целевыми характеристиками, робот остановится
-- 7.16. Перед стартом робот отфильтрует сундук R0 (сундук с фильтрами) от дубликатов
-- 7.17. В центре поля можно установить crop-matron или источник воды. Главное условие чтобы на уровне жёрдочек был полный блок. Это позволит роботу понять, что это техническое место. Трубы могут уходить вверх или в низ. Робот их объедет
-- 7.18. Если сундук L2 (продукты) забьётся - робот будет выкидывать продукт в R2 (Мусорку)
-- 7.19. Чтобы вырастить растение не имея его в наличии достаточно указать в параметрах имя растения (параметр target) и поместить в белый список родителей из которых можно вывести его
-- 7.20. В случае если выключены гибриды (--hybrid=off) но робот сумел получить семечко, а также его нет в чёрном списке - робот поместит его в сундук с фильтрами
-- 7.21. Если в вашем сборке робот дублирует семена - меняйте `settings.seedPlaceMethod`.
-- 7.22. Если кроп был просканирован роботом, то при сборе выпадет отсканированное семечко. Закладывать сканер при проектировании базы не нужно.
-- 7.23. Если редактируете этот скрипт, то после сохранения изменений на диск робота, сломайте и переставьте его. Не забудьте про лопату.

local robot = require("robot")
local computer = require("computer")
local component = require("component")
local term = require("term")
local shell = require("shell")
local geo = component.geolyzer
local inventory = component.inventory_controller

local MAX_GROWTH = 24 -- значение характеристики growth, при котором и выше которого робот будет убивать растение на корню

local IC2_BLOCK_CROP = "IC2:blockCrop"
local IC2_ITEM_WEED_EX = "IC2:itemWeedEx"

-----------------------------------------------------
print "hello ww" 
local settings = {
    seedPlaceMethod = 'use', -- nil, use, place
    shutdown = true,
    cropname = nil,
    growth = 22,
    gain = 31,
    resistance = 4,
    hybrid = 4
}
local beeps = {}
local underground = -6
local parking = {
    dir = 'T',
    x = 0,
    y = -1,
    z = 0
}
local robotInventory = nil
local blacklist = {
    n = 0
}
local whitelist = {
    n = 0
}
local uniqueHybrids = {}
local weeds = {
    ["venomilia"] = true,
    ["tin oreberry"] = true,
    ["ardite berry"] = true,
    ["cobalt berry"] = true,
    ["gold oreberry"] = true,
    ["iron oreberry"] = true,
    ["copper oreberry"] = true,
    ["knightly oreberry"] = true,
    ["aluminium oreberry"] = true
}
local oresCache = {}
local chests = {
    -- Тут можно поменять расположение сундуков.
    -- Важно, что робот должен иметь доступ к каждому сундуку - иметь возвожность встать на клетку непосредственно сбоку
    -- не забываем, что корневая точка маршрута робота - точка GG. Рядом с ней должен стоять OpenComputers charger.
    -- dir = 'L' - горизонтальна плоскость слева от стартовой точки GG
    -- dir = 'R' - горизонтальна плоскость справа от стартовой точки GG
    -- x - смещение вдоль оси "ширины" поля. Значения кроме 0 не тестировались
    -- y - смещение вдоль оси "высоты" поля. Положительные значения перекроют доступ робота к блокам поля
    -- z - смещение по высоте. 0 - уровень стартовой точки
    -- координата (0, 0, 0) с dir = 'L' соответсвует сундуку L1
    -- координата (0, 0, 0) с dir = 'R' соответсвует сундуку R1

    seed = { -- место с семенами для размножения
        -- L1 - сундук, куда будут помещаться мешочки с материнскими культурами.
        dir = 'L',
        x = 0,
        y = 0,
        z = 0
    },

    crop = { -- жёрдочки
        -- R1 - сундук с палками, водой, удобрениями, киркой, рудой под растения и weed-ex
        dir = 'R',
        x = 0,
        y = 0,
        z = 0
    },
    tools = { -- weed-ex, fertilizer, hydrotion cells
        -- R1 - сундук с палками, водой, удобрениями, киркой, рудой под растения и weed-ex
        dir = 'R',
        x = 0,
        y = 0,
        z = 0
    },
    pickaxe = { -- кирки
        -- R1 - сундук с палками, водой, удобрениями, киркой, рудой под растения и weed-ex
        dir = 'R',
        x = 0,
        y = 0,
        z = 0
    },
    ore = { -- руда
        -- R1 - сундук с палками, водой, удобрениями, киркой, рудой под растения и weed-ex
        dir = 'R',
        x = 0,
        y = 0,
        z = 0
    },
    command = { -- команды
        -- R1 - сундук с палками, водой, удобрениями, киркой, рудой под растения и weed-ex
        dir = 'R',
        x = 0,
        y = 0,
        z = 0
    },

    product = { -- урожай
        -- L2 - сундук, куда будут помещаться урожай (сундук не обязателен)
        required = false,
        dir = 'L',
        x = 0,
        y = -1,
        z = 0
    },
    hybrid = { -- гибриды
        -- L0 - сундук, куда будут помещаться гибриды (сундук не обязателен)
        required = false,
        dir = 'L',
        x = 0,
        y = 0,
        z = -1
    },

    trashcan = { -- Всё остальное что не было распознано
        -- R2 - сундук для мусора, куда будут помещаться негодное растение, целевые семена низкого качества а также сорняки
        dir = 'R',
        x = 0,
        y = -1,
        z = 0
    },

    filter = { -- сундук с чёрным списком семян. Имеет смысл если разведение гибридов выключено
        -- R0 - Фильтр для семян. 1. Семена - чёрный список. 2. Бумага переименованная на наковальне - белый список (сундук не обязателен)
        required = false,
        dir = 'R',
        x = 0,
        y = 0,
        z = -1
    }

}

local customSeedsMaxSize = {
    ["ardite berry"] = 3
}

local seedOres = {
    argentia = {"54", "1054", "2054", "3054", "4054", "5054", "6054", "gt.blockmetal6.10.name", "block of silver",
                "silver ore"},
    aurelia = {"gold ore", "ancient gold block", "block of gold"},
    ["ardite berry"] = {"block of ardite"},
    ferru = {"iron ore", "block of iron"},
    bauxia = {"block of aluminium", "block of aluminum", "aluminium ore", "gt.blockmetal1.1.name", "6019", "5019",
              "4019", "3019", "2019", "19", "1019"},
    bobsyeruncleranks = {"block of emerald", "emerald ore", "501", "1501", "2501", "3501", "4501", "5501", "6501"},
    coppon = {"block of copper", "copper ore", "copper block", "35", "1035", "2035", "3035", "4035", "5035", "6035"},
    diareed = {"6500", "4500", "5500", "3500", "1500", "2500", "500", "block of diamond", "diamond ore"},
    galvania = {"zinc ore", "block of zinc", "36", "1036", "2036", "3036", "4036", "5036", "6036",
                "gt.blockmetal8.6.name"},
    ["god of thunder"] = {"thorium ore", "block of thorium", "96", "1096", "2096", "3096", "4096", "5096", "6096",
                          "gt.blockmetal7.5.name"},
    lazulia = {"ancient lapis lazuli block", "lapis ore", "6526", "5526", "4526", "3526", "2526", "1526", "526"},
    micadia = {"mica ore", "901", "2901", "3901", "4901", "5901", "6901", "1901"},
    nickelback = {"nickel ore", "block of nickel", "34", "1034", "2034", "3034", "4034", "5034", "6034",
                  "gt.blockmetal5.4.name"},
    olivia = {"olivine ore", "block of olivine", "505", "1505", "2505", "3505", "4505", "5505", "6505",
              "gt.blockgem2.4.name"},
    platina = {"platinum ore", "block of platinum", "85", "2085", "3085", "4085", "5085", "6085",
               "gt.blockmetal5.12.name", "1085"},
    plumbilia = {"decorative lead block", "lead ore", "block of lead", "lead block", "3089", "block of lead", "4089",
                 "lead ore", "lead block", "gt.blockmetal4.2.name", "6089", "2089", "1089", "5089", "89"},
    pyrolusium = {"block of manganese", "manganese ore", "gt.blockmetal4.6.name", "5031", "4031", "6031", "2031",
                  "1031", "31", "3031"},
    quantaria = {"iridium ore", "block of iridium", "84", "1084", "2084", "3084", "4084", "5084", "6084",
                 "gt.blockmetal3.12.name"},
    reactoria = {"uranium ore", "block of uranium 238", "gt.blockmetal7.14.name", "uranium block"},
    sapphirum = {"sapphire ore", "block of sapphire", "gt.blockgem2.12.name", "6503", "4503", "5503", "3503", "2503",
                 "1503", "503"},
    scheelinium = {"decorative tungsten block", "block of tungsten", "tungsten ore", "gt.blockmetal7.11.name", "6081",
                   "5081", "4081", "3081", "1081", "2081", "81"},
    stargatium = {"block of naquadah", "naquadah ore", "gt.blockmetal4.12.name", "324", "2324", "1324", "3324", "4324",
                  "5324", "6324"},
    starwart = {"nether star block", "nether star ore", "block of nether star", "506", "1506", "2506", "3506", "6506",
                "gt.blockgem3.3.name", "5506", "4506"},
    tine = {"block of tin", "tin ore", "tin block", "gt.blockmetal7.7.name", "5057", "4057", "57", "6057", "3057",
            "2057", "1057"},
    titania = {"block of titanium", "titanium ore", "gt.blockmetal7.9.name", "6028", "5028", "4028", "3028", "2028",
               "1028", "28"},
    withereed = {"coal ore", "block of coal", "colored block of coal (white frequency)", "535", "1535", "2535", "3535",
                 "4535", "5535", "6535"},
    ["black stonelilly"] = {"mossy black granite cobblestone", "black granite", "black granite cobblestone",
                            "gt.blockgranites.2.name", "gt.blockgranites.0.name", "gt.blockgranites.1.name"},
    cinderpearl = {"block of blaze", "gt.blockgem3.5.name"},
    ["cobalt berry"] = {"block of cobalt", "gt.blockmetal2.5.name"},
    garnydinia = {"yellow garnet ore", "red garnet ore", "block of yellow garnet", "block of red garnet", "1528", "528",
                  "6527", "5527", "4527", "3527", "2527", "1527", "527", "6528", "5528", "4528", "3528", "2528",
                  "gt.blockgem3.2.name", "gt.blockgem2.10.name"},
    ["gray stonelilly"] = {"cobblestone"},
    ["nether stonelilly"] = {"nether brick", "netherrack"},
    ["red stonelilly"] = {"red granite bricks", "mossy red granite cobblestone", "red granite cobblestone",
                          "red granite", "smooth red granite", "chiseled red granite", "mossy red granite bricks",
                          "cracked red granite bricks", "gt.blockgranites.11.name", "gt.blockgranites.10.name",
                          "gt.blockgranites.9.name", "gt.blockgranites.8.name", "gt.blockgranites.15.name",
                          "gt.blockgranites.14.name", "gt.blockgranites.13.name", "gt.blockgranites.12.name"},
    shimmerleaf = {"quicksilver block", "quicksilver brick"},
    ["white stonelilly"] = {"marble", "gt.blockstones.0.name", "diorite"},
    ["yellow stonelilly"] = {"end stone", "sandstone"},
    cyprium = {"copper block", "copper ore", "decorative copper block", "block of copper", "gt.blockmetal2.7.name"},
    plumbiscus = {"block of lead", "decorative lead block", "lead block", "lead ore", "gt.blockmetal4.2.name"},
    stagnium = {"tin ore", "tin block", "block of tin"},
    ["magic metal berry"] = {"block of iron", "void metal block", "block of thaumium", "thauminite block",
                             "gt.blockmetal7.4.name"},
    ["magical nightshade"] = {"block of ichorium", "gt.blockmetal8.13.name"},
    ["space plant"] = {"moon dirt", "moon rock", "moon turf", "moon dungeon brick"},
    ["knightly oreberry"] = {"block of knightmetal"},
    ["mana bean"] = {"air crystal cluster", "fire crystal cluster", "water crystal cluster", "earth crystal cluster",
                     "order crystal cluster", "entropy crystal cluster", "mixed crystal cluster"}
}

local filters = {
    air = function(item)
        return item.name == 'air'
    end,
    weed = function(item)
        return item.name == "IC2:itemWeed"
    end,
    crop = function(item)
        return item.name == IC2_BLOCK_CROP
    end,
    seed = function(item)
        return item.name == "IC2:itemCropSeed"
    end,
    weedEx = function(item)
        return item.name == IC2_ITEM_WEED_EX and item.damage ~= item.maxDamage
    end,
    hydration = function(item)
        return item.name == "IC2:itemCellHydrant" and item.damage ~= item.maxDamage
    end,
    fertilizer = function(item)
        return item.name == "IC2:itemFertilizer" or item.name == "minecraft:dye" and item.damage == 15
    end,
    pickaxe = function(item)
        return item.label ~= nil and string.find(string.lower(item.label), 'pickaxe') and item.damage ~= item.maxDamage
    end,
    command = function(item)
        return item.name == 'minecraft:paper' and string.find(item.label, ':')
    end,
    ore = function(item)
        return getOreSeeds(item).n > 0
    end
}

---------------------- helpers ----------------------

function isMotherPosition(pos)
    return ((pos + 1) % 2) == 1
end

function getTableSize(t)
    local count = 0
    for _, __ in pairs(t) do
        count = count + 1
    end
    return count
end

function getEnergyLevel()
    return math.floor(computer.energy() * 100 / computer.maxEnergy())
end

---------------------- logger ----------------------

logger = {
    width = 50,
    height = 16,
    lines = {},

    success = function(msg)
        local file = io.open("/home/crop_stats.log", "a")
        file:write(msg .. "\n")
        file:close()

        logger.push(msg)
        computer.beep(1000, 0.3)
        computer.beep(1000, 0.3)
        computer.beep(1000, 0.3)
        os.sleep(10)
        computer.shutdown()
    end,

    print = function(msg)
        logger.push("[" .. robotXYZD.x .. " " .. robotXYZD.y .. " " .. robotXYZD.z .. "]: " .. msg)
    end,

    push = function(msg)

        if logger.lines[logger.height - 6] ~= nil then
            local lines = {}

            for i = 2, logger.height - 6 do
                if logger.lines[i] ~= nil then
                    table.insert(lines, logger.lines[i])
                end
            end

            logger.lines = lines
        end

        if utf8.len(msg) >= logger.width then
            msg = string.sub(msg, 1, utf8.offset(msg, logger.width - 3) - 1) .. "..."
        end

        if logger.lines[#logger.lines] ~= msg then
            table.insert(logger.lines, msg)
        end

        logger.refresh()
    end,

    dump = function(o)

        if type(o) == 'table' then
            local s = '{ '

            for k, v in pairs(o) do

                if type(k) ~= 'number' then
                    k = '"' .. k .. '"'
                end

                s = s .. '[' .. k .. '] = ' .. logger.dump(v) .. ', '
            end

            return s .. '} '
        else
            return tostring(o)
        end

    end,

    refresh = function()
        term.clear()
        term.write("Скрипт для разведения растений\n")
        term.write("Версия: " .. ver .. "\n")
        term.write("Размер: " .. Garden.width .. ' x ' .. Garden.height .. "\n")

        if settings.cropname ~= nil then
            local maxStats = {
                growth = '-',
                gain = '-',
                resistance = '-',
                level = -1
            }

            for pos = 1, Garden.size do

                if isMotherPosition(pos) then
                    local stats = Garden.seeds[pos]

                    if stats and stats.block == 'seed' and stats.cropname == settings.cropname and maxStats.level <
                        stats.level then
                        maxStats = stats
                    end

                end

            end

            term.write("Целевое растение: " .. settings.cropname .. " (" .. maxStats.growth .. " " ..
                           maxStats.gain .. " " .. maxStats.resistance .. ") / (" .. settings.growth .. " " ..
                           settings.gain .. " " .. settings.resistance .. ")\n")
        else
            term.write("Целевое растение: -\n")
        end

        if settings.hybrid == 0 then
            term.write("Выращивать гибриды: Нет\n")
        elseif whitelist.n > 0 then
            term.write("Выращивать гибриды: Да (W: " .. whitelist.n .. "; B: " .. blacklist.n ..
                           ")\n")
        else
            term.write("Выращивать гибриды: Да (B: " .. blacklist.n .. ")\n")
        end

        if settings.shutdown then
            term.write("Если ошибка: выкл.\n")
        else
            term.write("Если ошибка: ждать.\n")
        end

        for i = 1, #logger.lines do
            term.write("\n" .. logger.lines[i])
        end

    end

}

logger.width, logger.height = term.getViewport()

---------------------- movements -------------------

robotXYZD = {
    dir = parking.dir,
    x = parking.x,
    y = parking.y,
    z = parking.z,

    obstacles = {},

    forward = function(x, y)
        local guid = (robotXYZD.x + x) .. ' ' .. (robotXYZD.y + y) .. ' ' .. robotXYZD.z

        if robotXYZD.obstacles[guid] ~= nil then
            return robotXYZD.obstacles[guid]
        else
            local success, block = robot.forward()

            if block == 'solid' then
                robotXYZD.obstacles[guid] = block
            end

            if success then
                return nil
            else
                return block or 'undefined'
            end

        end

    end,

    XYZDFromPosition = function(pos, z)
        pos = pos - 1

        local halfX = math.floor(Garden.width / 2)
        local xyzd = {
            x = math.floor(pos / Garden.height) - halfX,
            y = (pos % Garden.height) + 1,
            z = z
        }

        if (xyzd.x + halfX) % 2 ~= 0 then
            xyzd.y = Garden.height - xyzd.y + 1
        end

        return xyzd
    end,

    positionFromXYZD = function(posX, posY)
        local halfX = math.floor(Garden.width / 2)
        local x = (posX + halfX) * Garden.height
        local y = posY - 1

        if (posX + halfX) % 2 ~= 0 then
            y = Garden.height - posY
        end

        return x + y + 1
    end,

    currentPosition = function()
        return robotXYZD.positionFromXYZD(robotXYZD.x, robotXYZD.y)
    end,

    currentXYZD = function()
        return {
            dir = robotXYZD.dir,
            x = robotXYZD.x,
            y = robotXYZD.y,
            z = robotXYZD.z
        }
    end,

    rotate = function(dir)

        if ((robotXYZD.dir == "T" and dir == "B") or (robotXYZD.dir == "B" and dir == "T") or
            (robotXYZD.dir == "L" and dir == "R") or (robotXYZD.dir == "R" and dir == "L")) then
            robot.turnAround()
        elseif ((robotXYZD.dir == "L" and dir == "T") or (robotXYZD.dir == "T" and dir == "R") or
            (robotXYZD.dir == "R" and dir == "B") or (robotXYZD.dir == "B" and dir == "L")) then
            robot.turnRight()
        elseif ((robotXYZD.dir == "L" and dir == "B") or (robotXYZD.dir == "B" and dir == "R") or
            (robotXYZD.dir == "R" and dir == "T") or (robotXYZD.dir == "T" and dir == "L")) then
            robot.turnLeft()
        end

        robotXYZD.dir = dir
    end,

    jumpX = function(step)
        local y = robotXYZD.y
        local x = robotXYZD.x
        local dir = robotXYZD.dir

        if y > 1 then
            robotXYZD.moveY(y - 1)
        else
            robotXYZD.moveY(y + 1)
        end

        robotXYZD.moveX(x + step * 2)
        robotXYZD.moveY(y)
        robotXYZD.rotate(dir)
    end,

    jumpY = function(step)
        local y = robotXYZD.y
        local x = robotXYZD.x
        local dir = robotXYZD.dir

        if x > 1 then
            robotXYZD.moveX(x - 1)
        else
            robotXYZD.moveX(x + 1)
        end

        robotXYZD.moveY(y + step * 2)
        robotXYZD.moveX(x)
        robotXYZD.rotate(dir)
    end,

    moveX = function(targetX)
        if robotXYZD.x == targetX then
            return true
        end
        local dir = nil

        if robotXYZD.x > targetX then
            robotXYZD.rotate('L')
            dir = -1
        elseif robotXYZD.x < targetX then
            robotXYZD.rotate('R')
            dir = 1
        end

        while robotXYZD.x ~= targetX do
            local err = robotXYZD.forward(dir, 0)

            if not err then
                robotXYZD.x = robotXYZD.x + dir
            elseif err == 'entity' then
                logger.push("Отойдите пожалуйста!")
                computer.beep(1000, 0.3)
                os.sleep(1) -- останавливаем робота на 1 секунду
            elseif err == 'impossible move' then
                error("Слишком высоко. Я боюсь летать выше 7 блоков!")
            elseif err == 'already moving' then
                logger.push("Привет TPS!")
                os.sleep(0.5) -- останавливаем робота на 1 секунду
            else
                logger.push("moveX err:" .. err)

                if robotXYZD.x + dir ~= targetX then
                    robotXYZD.jumpX(dir)
                else
                    break
                end

            end

        end

        return robotXYZD.x == targetX
    end,

    moveY = function(targetY)
        if robotXYZD.y == targetY then
            return true
        end
        local dir = nil

        if robotXYZD.y > targetY then
            robotXYZD.rotate('B')
            dir = -1
        elseif robotXYZD.y < targetY then
            robotXYZD.rotate('T')
            dir = 1
        end

        while robotXYZD.y ~= targetY do
            local err = robotXYZD.forward(0, dir)

            if not err then
                robotXYZD.y = robotXYZD.y + dir
            elseif err == 'entity' then
                logger.push("Отойдите пожалуйста!")
                computer.beep(1000, 0.3)
                os.sleep(1) -- останавливаем робота на 1 секунду
            elseif err == 'impossible move' then
                error("Слишком высоко. Я боюсь летать выше 7 блоков!")
            elseif err == 'already moving' then
                logger.push("Привет TPS!")
                os.sleep(0.5) -- останавливаем робота на 1 секунду
            else
                logger.push("moveY err:" .. err)

                if robotXYZD.y + dir ~= targetY then
                    robotXYZD.jumpY(dir)
                else
                    break
                end
            end

        end

        return robotXYZD.y == targetY
    end,

    moveZ = function(targetZ)
        if robotXYZD.z == targetZ then
            return
        end
        local action = nil
        local dir = nil

        if robotXYZD.z > targetZ then
            action = robot.down
            dir = -1
        elseif robotXYZD.z < targetZ then
            action = robot.up
            dir = 1
        end

        while robotXYZD.z ~= targetZ do
            local success, err = action()

            if success then
                robotXYZD.z = robotXYZD.z + dir
            elseif err == 'entity' then
                logger.push("Отойдите пожалуйста!")
                computer.beep(1000, 0.3)
                os.sleep(1) -- останавливаем робота на 1 секунду
            elseif err == 'already moving' then
                logger.push("Привет TPS!")
                os.sleep(0.5) -- останавливаем робота на 1 секунду
            else
                logger.push("Робот столкнулся с препятствием")
                logger.push(" при перемещении на z=" .. targetZ .. ".")
                logger.push("moveZ err:" .. err)
                computer.beep(1000, 0.3)
                os.sleep(1) -- останавливаем робота на 1 секунду
            end

        end

        return robotXYZD.z == targetZ
    end,

    go = function(xyzd)

        if robotXYZD.z ~= xyzd.z then -- если находится в туннеле

            while (true) do
                local x = robotXYZD.x
                local y = robotXYZD.y

                if robotXYZD.x ~= 0 then
                    robotXYZD.moveX(0)
                end

                if robotXYZD.y ~= 0 then
                    robotXYZD.moveY(0)
                end

                if robotXYZD.x == x and robotXYZD.y == y then
                    break
                end

            end

            robotXYZD.moveZ(xyzd.z)
        end

        if robotXYZD.y <= 0 and xyzd.y > 0 then -- находится среди сундуков
            robotXYZD.moveY(xyzd.y)
        end

        while (true) do
            local x = robotXYZD.x
            local y = robotXYZD.y

            if robotXYZD.x ~= xyzd.x then
                robotXYZD.moveX(xyzd.x)
            end

            if robotXYZD.y ~= xyzd.y then
                robotXYZD.moveY(xyzd.y)
            end

            if robotXYZD.x == x and robotXYZD.y == y then
                break
            end

        end

        if xyzd.dir ~= nil and robotXYZD.dir ~= xyzd.dir then
            robotXYZD.rotate(xyzd.dir)
        end

        return robotXYZD.x == xyzd.x and robotXYZD.y == xyzd.y
    end

}

---------------------- coordinates -------------------

local Chest = {}

function Chest:new(xyzd)
    local private = {}
    local public = {}
    private.size = nil
    private.name = nil

    function public:guid()
        return xyzd.x .. ' ' .. xyzd.y .. ' ' .. xyzd.z .. ' ' .. xyzd.dir
    end

    function public:size()

        if private.name == nil then
            private.name = geo.analyze(3).name
        end

        if private.size == nil or private.name == 'ExtraUtilities:filling' then
            robotXYZD.go(xyzd)
            private.size = math.floor(inventory.getInventorySize(3))
        end

        return private.size
    end

    function public:forEach(callback)
        local slotIndex = public:size()

        while slotIndex > 0 and callback(slotIndex, public:get(slotIndex)) ~= false do
            slotIndex = slotIndex - 1
        end

    end

    function public:find(filter)
        local slotIndex = public:size()

        while slotIndex > 0 do
            local item = public:get(slotIndex)

            if filter(item) then
                return slotIndex, item
            end

            slotIndex = slotIndex - 1
        end

        return nil, nil
    end

    function public:filter(filter)
        local slotIndex = public:size()
        local result = {}

        while slotIndex > 0 do
            local item = public:get(slotIndex)

            if filter(item) then
                result[slotIndex] = item
            end

            slotIndex = slotIndex - 1
        end

        return result
    end

    function public:get(slotIndex)
        robotXYZD.go(xyzd)
        return inventory.getStackInSlot(3, slotIndex) or ({
            name = 'air',
            size = 0
        })
    end

    function public:suck(slotIndex, internalSlotIndex, count)
        local result = false
        robotXYZD.go(xyzd)

        if internalSlotIndex == nil then
            robot.select(1)
            result = inventory.suckFromSlot(3, slotIndex, count)
            robotInventory:updateSlot(1)
            robotInventory:resetCacheFor()
        else
            robot.select(internalSlotIndex)
            result = inventory.suckFromSlot(3, slotIndex, count)
            robotInventory:updateSlot(internalSlotIndex)
        end

        return result
    end

    function public:drop(internalSlotIndex, count)
        robotXYZD.go(xyzd)

        robot.select(internalSlotIndex)
        local result = robot.drop(count)
        robotInventory:updateSlot(internalSlotIndex)

        return result
    end

    -- чистая магия!
    setmetatable(public, self)
    self.__index = self
    return public
end

---------------------- inventory -------------------

local Inventory = {}

function Inventory:new(xyzd)
    local private = {}
    local public = {}
    private.slots = {}
    private.size = nil

    function private:slot(slotIndex)
        return inventory.getStackInInternalSlot(slotIndex) or ({
            name = 'air',
            size = 0
        })
    end

    function public:size()

        if private.size == nil then
            private.size = math.floor(robot.inventorySize())
        end

        return private.size
    end

    function public:resetCacheFor(filter)
        air = true

        for slotIndex = 1, public:size() do
            local item = private.slots[slotIndex]

            if item ~= nil then

                if filter and filter(item) then
                    private.slots[slotIndex] = nil
                elseif air and item.name == 'air' then
                    private.slots[slotIndex] = private:slot(slotIndex)
                    air = item.name ~= private.slots[slotIndex].name
                end

            end

        end

    end

    function public:updateSlot(slotIndex)
        private.slots[slotIndex] = nil
    end

    function public:forEach(callback)
        local slotIndex = public:size()

        while slotIndex > 0 and callback(slotIndex, public:get(slotIndex)) ~= false do
            slotIndex = slotIndex - 1
        end

    end

    function public:find(filter)

        for slotIndex = 1, public:size() do
            local item = public:get(slotIndex)

            if filter(item) then
                return slotIndex, item
            end

        end

        return nil
    end

    function public:filter(filter)
        local result = {}

        for slotIndex = 1, public:size() do
            local item = public:get(slotIndex)

            if filter(item) then
                result[slotIndex] = item
            end

        end

        return result
    end

    function public:get(slotIndex)

        if not private.slots[slotIndex] then
            private.slots[slotIndex] = private:slot(slotIndex)
        end

        return private.slots[slotIndex]
    end

    function public:count(filter)
        local count = 0

        filter = filter or filters.air

        for slotIndex = 1, public:size() do

            if filter(public:get(slotIndex)) then
                count = count + 1
            end

        end

        return count
    end

    function public:isFull(freeSize)
        local size = 0
        freeSize = freeSize or 3

        for slotIndex = 1, public:size() do

            if filters.air(public:get(slotIndex)) then
                size = size + 1

                if size == freeSize then
                    return false
                end
            end

        end

        return true
    end

    function public:plantSeed(seedSlotIndex, stats)
        local block = stats.block

        if block == 'seed' and stats.size ~= stats.maxSize then
            robot.useDown()
            public:resetCacheFor()
        end

        if block ~= 'air' then -- если не сбить палки тогда перестанут выпадать семена
            robot.swingDown()
            public:resetCacheFor(filters.crop)
        end

        local cropIndex = public:find(function(item)
            return filters.crop(item) and item.size > 1
        end)

        if cropIndex ~= nil then
            public:place(cropIndex, robot.placeDown) -- ставим палку на землю
            public:updateSlot(cropIndex)

            if settings.seedPlaceMethod == nil then
                public:place(seedSlotIndex, robot.placeDown) -- сажаем
                settings.seedPlaceMethod = 'place'

                if robot.count(seedSlotIndex) ~= 0 then
                    public:use(seedSlotIndex, robot.useDown) -- сажаем
                    settings.seedPlaceMethod = 'use'
                end

            elseif settings.seedPlaceMethod == 'place' then
                public:place(seedSlotIndex, robot.placeDown) -- сажаем
            else
                public:use(seedSlotIndex, robot.useDown) -- сажаем
            end

            public:updateSlot(seedSlotIndex)

            local weedExIndex = robotInventory:find(filters.weedEx)

            if weedExIndex ~= nil then
                robotInventory:use(weedExIndex, robot.useDown)
            end

            return true
        end

        return false
    end

    function public:use(slotIndex, action)
        robot.select(slotIndex)

        inventory.equip()
        local a, b = action()
        inventory.equip()

        public:updateSlot(slotIndex)

        return a, b
    end

    function public:place(slotIndex, action)
        robot.select(slotIndex)

        local result = action()

        public:updateSlot(slotIndex)

        return result
    end

    function public:clean(currPosition)
        local continue = {}
        local tools = {}
        local places = {
            seed = {},
            hybrid = {},
            ore = {},
            tools = {},
            command = {},
            crop = {},
            product = {},
            trashcan = {},
            pickaxe = {},
            filter = {}
        }

        public:resetCacheFor(filters.air)

        if currPosition then

            Garden.forEach(Garden.getSeedsFrom(function(filter)
                return robotInventory:filter(filter)
            end), function(gardenPosition, seedSlotIndex)

                if gardenPosition >= currPosition then
                    continue[seedSlotIndex] = true
                end

            end)

            for gardenPosition = currPosition + 1, Garden.size do
                local stats = Garden.seeds[gardenPosition]

                if stats ~= nil and stats.block == 'seed' and seedOres[stats.cropname] ~= nil and
                    oresCache[stats.cropname] ~= nil and stats.size + 1 == stats.maxSize and
                    (Garden.ores[pos] == nil or Garden.ores[pos] ~= stats.cropname) then
                    local slotIndex = robotInventory:find(function(item)
                        return getOreSeeds(item)[stats.cropname]
                    end)

                    if slotIndex then
                        continue[slotIndex] = true
                    end

                end

            end

        end

        for slotIndex = 1, public:size() do
            local item = public:get(slotIndex)

            if continue[slotIndex] then
                -- continue;
            elseif filters.crop(item) and item.size > 3 and not tools.crop then
                tools.crop = true
            elseif filters.weedEx(item) and not tools.weedEx then
                tools.weedEx = true
            elseif filters.hydration(item) and not tools.hydration then
                tools.hydration = true
            elseif filters.fertilizer(item) and not tools.fertilizer then
                tools.fertilizer = true
            elseif filters.pickaxe(item) and not tools.pickaxe then
                tools.pickaxe = true
            elseif item.name ~= 'air' then

                if filters.seed(item) then -- определяем место для полученного продукта
                    local stats = convertSlotToStats(item)

                    if seedIsWeed(stats) then
                        places.trashcan[slotIndex] = true
                    elseif stats.cropname == settings.cropname or seedMayBePlanted(stats) then
                        places.seed[slotIndex] = true
                    elseif inBlackList(stats) then

                        if not blacklist[stats.cropname] and chests.filter then

                            blacklist[stats.cropname] = true
                            blacklist.n = blacklist.n + 1
                            logger.push('Добавлен в чёрный список ' .. stats.cropname)

                            places.filter[slotIndex] = true
                        else
                            places.trashcan[slotIndex] = true
                        end

                    elseif chests.hybrid then
                        uniqueHybrids[stats.cropname] = (uniqueHybrids[stats.cropname] or 0) + 1
                        places.hybrid[slotIndex] = true
                    else
                        places.trashcan[slotIndex] = true
                    end

                elseif filters.crop(item) then
                    places.crop[slotIndex] = true
                elseif filters.weed(item) then
                    places.trashcan[slotIndex] = true
                elseif item.name == IC2_ITEM_WEED_EX and item.damage == item.maxDamage then
                    places.trashcan[slotIndex] = true
                elseif filters.weedEx(item) or filters.hydration(item) or filters.fertilizer(item) then
                    places.tools[slotIndex] = true
                elseif filters.ore(item) then
                    places.ore[slotIndex] = true
                elseif filters.command(item) then
                    places.command[slotIndex] = item.label
                elseif filters.pickaxe(item) then
                    places.pickaxe[slotIndex] = true
                elseif chests.product then
                    places.product[slotIndex] = true
                else
                    places.trashcan[slotIndex] = true
                end

            end

        end

        places.ore = InventorySort.dropItemsFromCache(chests.ore, places.ore)
        places.tools = InventorySort.dropItemsFromCache(chests.tools, places.tools)
        places.pickaxe = InventorySort.dropItemsFromCache(chests.pickaxe, places.pickaxe)
        places.crop = InventorySort.dropItemsFromCache(chests.crop, places.crop)
        InventorySort.dropItemsFromCache(chests.command, places.command)
        places.filter = InventorySort.dropItemsFromCache(chests.filter, places.filter, chests.trashcan)
        places.hybrid = InventorySort.dropItemsFromCache(chests.hybrid, places.hybrid, chests.trashcan)
        places.product = InventorySort.dropItemsFromCache(chests.product, places.product, chests.trashcan)

        -- seeds
        for slotIndex, _ in pairs(places.seed) do
            if not chests.seed:drop(slotIndex, 64) then
                removeSeedsWithBadStats()

                if not chests.seed:drop(slotIndex, 64) then
                    destroyAllDoubleCrops()
                    logger.success("Работа выполнена")
                end

            end
        end
        places.seed = nil

        InventorySort.dropItemsFromCache(chests.trashcan, places.trashcan) -- trashcan

        for _, command in pairs(places.command) do
            Command.run(command)
        end

    end

    function public:swingUp()
        local index = 1

        while index < 15 and robot.detectUp() do

            if index > 1 then
                os.sleep(0.5)
            end

            if robot.swingUp() == false then
                return false
            end

            index = index + 1
        end

        return index < 15
    end

    -- чистая магия!
    setmetatable(public, self)
    self.__index = self
    return public
end

-------------------------------------------------------

InventorySort = {

    dropItemsFromCache = function(chest, cache, trashcan)

        if not chest then
            chest = trashcan
            trashcan = nil
        end

        if not chest then
            destroyAllDoubleCrops()
            error("Сундук переполнен. Не могу выбросить")
        end

        for slotIndex in pairs(cache) do
            if not chest:drop(slotIndex, 64) then

                if not trashcan or not trashcan:drop(slotIndex, 64) then
                    destroyAllDoubleCrops()
                    error("Сундук переполнен. Не могу выбросить")
                end

            end
        end

        return nil
    end,

    dropPlaces = function(places)
        places.hybrid = InventorySort.dropItemsFromCache(chests.hybrid, places.hybrid, chests.trashcan) or {}
        places.filter = InventorySort.dropItemsFromCache(chests.filter, places.filter, chests.trashcan) or {}
        places.trashcan = InventorySort.dropItemsFromCache(chests.trashcan, places.trashcan) or {}
    end,

    suckOrDrop = function(places, minSlotIndex)
        local airIndex = robotInventory:find(filters.air)

        if not airIndex then
            InventorySort.dropPlaces(places)
            airIndex = robotInventory:find(filters.air)
        end

        if airIndex then
            chests.seed:suck(minSlotIndex, airIndex, 64)
        end

        return airIndex
    end

}

function removeSeedsWithBadStats()
    local maxSize = math.ceil(chests.seed:size() / 4)
    local seedsCount = chests.seed:size()
    local places = {
        trashcan = {},
        hybrid = {},
        filter = {}
    }

    for slotIndex = 1, chests.seed:size() do
        local item = chests.seed:get(slotIndex)
        local place = nil

        if filters.seed(item) then
            local stats = convertSlotToStats(item)

            if seedIsWeed(stats) then
                place = 'trashcan'
            elseif stats.cropname == settings.cropname then

                if not seedIsTarget(stats) and not seedMayBePlanted(stats) then
                    place = 'trashcan'
                end

            elseif inBlackList(stats) then

                if not blacklist[stats.cropname] and chests.filter then

                    blacklist[stats.cropname] = true
                    blacklist.n = blacklist.n + 1
                    logger.push('Добавлен в чёрный список ' .. stats.cropname)

                    place = 'filter'
                else
                    place = 'trashcan'
                end

            elseif chests.hybrid then
                uniqueHybrids[stats.cropname] = (uniqueHybrids[stats.cropname] or 0) + 1
                place = 'hybrid'
            else
                place = 'trashcan'
            end

        else
            place = 'trashcan'
        end

        if place then
            local index = InventorySort.suckOrDrop(places, slotIndex)

            if index then
                places[place][index] = true
                seedsCount = seedsCount - 1
            else
                break
            end

        end

        if seedsCount < maxSize then
            break
        end

    end

    InventorySort.dropPlaces(places)
end

-------------------------------------------------------

function createFilter()
    local weeds = {}

    chests.filter:forEach(function(slotIndex, item)

        if filters.seed(item) then
            local stats = convertSlotToStats(item)

            if stats and stats.cropname ~= settings.cropname then

                if blacklist[stats.cropname] == nil then
                    blacklist[stats.cropname] = true
                    blacklist.n = blacklist.n + 1
                else

                    local airIndex = robotInventory:find(filters.air)

                    if airIndex == nil then

                        for weedSlotIndex, _ in pairs(weeds) do
                            chests.trashcan:drop(weedSlotIndex, 1)
                        end

                        airIndex = robotInventory:find(filters.air)
                        weeds = {}
                    end

                    chests.filter:suck(slotIndex, airIndex, 1)
                    weeds[airIndex] = true
                end

            end

        elseif item.name == 'minecraft:paper' then
            local cropname = string.lower(item.label)

            if cropname ~= settings.cropname and whitelist[cropname] == nil then
                whitelist[cropname] = true
                whitelist.n = whitelist.n + 1
            end

        end

    end)

    for weedSlotIndex, _ in pairs(weeds) do
        chests.trashcan:drop(weedSlotIndex, 1)
    end

    if chests.hybrid then

        chests.hybrid:forEach(function(slotIndex, item)
            if filters.seed(item) then
                local stats = convertSlotToStats(item)
                if stats then
                    uniqueHybrids[stats.cropname] = (uniqueHybrids[stats.cropname] or 0) + 1
                end
            end
        end)

    end

end

function checkRobotEnergy()

    if getEnergyLevel() < 25 then
        local energyLevel = getEnergyLevel()
        logger.push('Отправились на подзарядку')
        robotXYZD.go(parking)

        while energyLevel < 95 do
            os.sleep(1)

            if getEnergyLevel() <= energyLevel then
                return false
            end

            energyLevel = getEnergyLevel()
        end

    end

    return true
end

function checkRobotState() -- todo оптимизировать чтобы робот дважды не ездил сперва очистить инвенрать а потом подзарядиться
    os.sleep(0.01)

    if robotInventory:isFull() or checkToolsInRobot(3) == false then
        robotInventory:clean(robotXYZD.currentPosition())
        getToolsForWorking()
    end

    if not checkRobotEnergy() then
        destroyAllDoubleCrops(true)
        error("Заряд кончился!")
    end

end

-------------------------------------------------------

Garden = {
    width = 7,
    height = 7,
    size = 7 * 7,

    seeds = {},
    ores = {},

    findSlotWithMaxLevel = function(items, level)
        local maxLevel = level or 0
        local maxSlot = nil

        for slotIndex, item in pairs(items) do

            if item and item.level > maxLevel then
                maxLevel = item.level
                maxSlot = slotIndex
            end

        end

        if maxSlot ~= nil then
            return {
                slotIndex = maxSlot,
                item = items[maxSlot]
            }
        end

        return nil
    end,

    findSlotWithMinLevel = function(items)
        local minLevel = 10000
        local minSlot = nil

        for slotIndex, item in pairs(items) do

            if item and item.level > 0 and item.level < minLevel then
                minLevel = item.level
                minSlot = slotIndex
            end

        end

        if minSlot ~= nil then
            return {
                slotIndex = minSlot,
                item = items[minSlot]
            }
        end

        return nil
    end,

    getPlaces = function(currPosition)
        local places = {
            air = {},
            target = {},
            blacklist = {},
            whitelist = {},
            other = {}
        }

        for pos = (currPosition or 1), Garden.size do

            if isMotherPosition(pos) then
                local stats = Garden.seeds[pos]

                if not stats or not stats.solid then

                    if not stats or stats.block ~= 'seed' then
                        places.air[pos] = {
                            size = 1,
                            level = pos
                        }
                    elseif whitelist[stats.cropname] then
                        places.whitelist[pos] = {
                            size = 1,
                            level = stats.level
                        }
                    elseif inBlackList(stats) then
                        places.blacklist[pos] = {
                            size = 1,
                            level = stats.level
                        }
                    elseif stats.cropname == settings.cropname and not seedIsTarget(stats) then
                        places.target[pos] = {
                            size = 1,
                            level = stats.level
                        }
                    elseif stats.cropname ~= settings.cropname then
                        places.other[pos] = {
                            size = 1,
                            level = stats.level
                        }
                    end

                end

            end

        end

        return places
    end,

    getSeedsFrom = function(callback)
        local uniqueSize = math.floor(Garden.size / math.max(whitelist.n, math.floor(Garden.size / 4)))
        local seeds = {}
        local inventory = {
            target = {},
            hybrid = {},
            whitelist = {},
            blacklist = {}
        }

        for pos = 1, Garden.size do

            if isMotherPosition(pos) then
                local stats = Garden.seeds[pos]

                if stats and stats.block == 'seed' then
                    seeds[stats.cropname] = (seeds[stats.cropname] or 0) + 1
                end

            end

        end

        local filter = function(item)

            if filters.seed(item) then
                local stats = convertSlotToStats(item)
                return not seedIsWeed(stats) and existsOreBlock(stats)
            end

            return false
        end

        for slotIndex, slot in pairs(callback(filter)) do
            local stats = convertSlotToStats(slot)

            if stats.cropname == settings.cropname then
                inventory.target[slotIndex] = {
                    size = slot.size,
                    level = stats.level
                }
            elseif whitelist[stats.cropname] and (not seeds[stats.cropname] or seeds[stats.cropname] < uniqueSize) then
                inventory.whitelist[slotIndex] = {
                    size = slot.size,
                    level = stats.level
                }
            elseif inBlackList(stats) or seeds[stats.cropname] and seeds[stats.cropname] > uniqueSize then
                inventory.blacklist[slotIndex] = {
                    size = slot.size,
                    level = stats.level
                }
            else
                inventory.hybrid[slotIndex] = {
                    size = slot.size,
                    level = stats.level
                }
            end

        end

        return inventory
    end,

    forEach = function(inventory, callback)
        if getTableSize(inventory.target) == 0 and getTableSize(inventory.hybrid) == 0 and
            getTableSize(inventory.whitelist) == 0 and getTableSize(inventory.blacklist) == 0 then
            return
        end

        local places = Garden.getPlaces()

        -- заполняем пустые места
        while true do
            local pos = Garden.findSlotWithMinLevel(places.air)

            if not pos then
                break
            end

            local slot = Garden.findSlotWithMaxLevel(inventory.target) or
                             Garden.findSlotWithMaxLevel(inventory.whitelist) or
                             Garden.findSlotWithMaxLevel(inventory.hybrid) or
                             Garden.findSlotWithMaxLevel(inventory.blacklist)

            if not slot or not callback(pos.slotIndex, slot.slotIndex) then
                return
            end

            places.air[pos.slotIndex] = nil

            if slot.item.size > 1 then
                slot.item.size = slot.item.size - 1
            else
                inventory.target[slot.slotIndex] = nil
                inventory.hybrid[slot.slotIndex] = nil
                inventory.whitelist[slot.slotIndex] = nil
                inventory.blacklist[slot.slotIndex] = nil
            end

        end

        -- заменяем растения в чёрном списке
        while true do
            local pos = Garden.findSlotWithMinLevel(places.blacklist)

            if not pos then
                break
            end

            local slot = Garden.findSlotWithMaxLevel(inventory.target) or
                             Garden.findSlotWithMaxLevel(inventory.whitelist) or
                             Garden.findSlotWithMaxLevel(inventory.hybrid) or
                             Garden.findSlotWithMaxLevel(inventory.blacklist, pos.item.level)

            if not slot or not callback(pos.slotIndex, slot.slotIndex) then
                return
            end

            places.blacklist[pos.slotIndex] = nil

            if slot.item.size > 1 then
                slot.item.size = slot.item.size - 1
            else
                inventory.target[slot.slotIndex] = nil
                inventory.hybrid[slot.slotIndex] = nil
                inventory.whitelist[slot.slotIndex] = nil
                inventory.blacklist[slot.slotIndex] = nil
            end

        end

        -- заменяем не целевое растения
        while true do
            local pos = Garden.findSlotWithMinLevel(places.other)

            if not pos then
                break
            end

            local slot = Garden.findSlotWithMaxLevel(inventory.target) or
                             Garden.findSlotWithMaxLevel(inventory.whitelist) or
                             Garden.findSlotWithMaxLevel(inventory.hybrid, pos.item.level)

            if not slot or not callback(pos.slotIndex, slot.slotIndex) then
                return
            end

            places.other[pos.slotIndex] = nil

            if slot.item.size > 1 then
                slot.item.size = slot.item.size - 1
            else
                inventory.target[slot.slotIndex] = nil
                inventory.hybrid[slot.slotIndex] = nil
                inventory.whitelist[slot.slotIndex] = nil
            end

        end

        -- заменяем растения в белом списке
        while true do
            local pos = Garden.findSlotWithMinLevel(places.whitelist)

            if not pos then
                break
            end

            local slot = Garden.findSlotWithMaxLevel(inventory.target) or
                             Garden.findSlotWithMaxLevel(inventory.whitelist, pos.item.level)

            if not slot or not callback(pos.slotIndex, slot.slotIndex) then
                return
            end

            places.whitelist[pos.slotIndex] = nil

            if slot.item.size > 1 then
                slot.item.size = slot.item.size - 1
            else
                inventory.target[slot.slotIndex] = nil
                inventory.whitelist[slot.slotIndex] = nil
            end

        end

        -- заменяем целевое растения
        while true do
            local pos = Garden.findSlotWithMinLevel(places.target)

            if not pos then
                break
            end

            local slot = Garden.findSlotWithMaxLevel(inventory.target, pos.item.level)

            if not slot or not callback(pos.slotIndex, slot.slotIndex) then
                return
            end

            places.target[pos.slotIndex] = nil

            if slot.item.size > 1 then
                slot.item.size = slot.item.size - 1
            else
                inventory.target[slot.slotIndex] = nil
            end

        end

    end,

    suckSeedsFromChest = function(currPosition)
        local MAX_SEEDS_IN_INVENTORY = math.ceil(robotInventory:size() / 4)
        local airCount = robotInventory:count(filters.air)
        local inserted = 0

        Garden.forEach(Garden.getSeedsFrom(function(filter)
            return chests.seed:filter(filter)
        end), function(gardenPosition, seedSlotIndex)

            if gardenPosition >= currPosition then
                if chests.seed:suck(seedSlotIndex, nil, 1) then
                    inserted = inserted + 1
                else
                    return false
                end
            end

            if inserted == MAX_SEEDS_IN_INVENTORY then
                inserted = robotInventory:count(filters.air) - airCount
                airCount = airCount - inserted
            end

            return inserted ~= MAX_SEEDS_IN_INVENTORY
        end)

        return inserted ~= 0, inserted == MAX_SEEDS_IN_INVENTORY
    end,

    findBestSeedsInInventory = function(position)
        local resultIndex = nil
        local inventory = Garden.getSeedsFrom(function(filter)
            return robotInventory:filter(filter)
        end)

        if Garden.seeds[position].block == 'air' then
            local slot = Garden.findSlotWithMaxLevel(inventory.target) or
                             Garden.findSlotWithMaxLevel(inventory.whitelist) or
                             Garden.findSlotWithMaxLevel(inventory.hybrid) or
                             Garden.findSlotWithMaxLevel(inventory.blacklist)
            return slot ~= nil and slot.slotIndex or nil
        end

        Garden.forEach(inventory, function(gardenPosition, seedSlotIndex)

            if position == gardenPosition then
                resultIndex = seedSlotIndex
            end

            return position ~= gardenPosition
        end)

        return resultIndex
    end,

    suckOresFromChest = function(currPosition)
        local MAX_ORES_IN_INVENTORY = math.ceil(robotInventory:size() / 4)
        local needWalk = false
        local inserted = 0
        local ores = nil

        for gardenPosition = currPosition, Garden.size do
            local stats = Garden.seeds[gardenPosition]
            local cropname = Garden.ores[gardenPosition]

            if stats and stats.block == 'seed' and seedOres[stats.cropname] then

                if stats.size + 1 == stats.maxSize and (not cropname or cropname ~= stats.cropname) then

                    if not ores then
                        ores = {}

                        chests.ore:forEach(function(index, item)
                            ores[index] = getOreSeeds(item)
                        end)

                    end

                    local oreIndex = nil

                    for index, seeds in pairs(ores) do
                        if seeds[stats.cropname] then
                            oreIndex = index
                            break
                        end
                    end

                    if oreIndex then
                        local slotIndex = robotInventory:find(function(item)
                            return getOreSeeds(item)[stats.cropname] and item.size < 64
                        end)
                        local air = false

                        if not slotIndex then
                            slotIndex = robotInventory:find(filters.air)
                            air = true
                        end

                        if slotIndex then
                            chests.ore:suck(oreIndex, slotIndex, 1)
                            ores[oreIndex] = getOreSeeds(chests.ore:get(oreIndex))

                            needWalk = true

                            if air then
                                inserted = inserted + 1
                            end

                        end

                    end

                elseif cropname and (cropname ~= stats.cropname or stats.size == stats.maxSize) then
                    needWalk = true
                end

            elseif cropname then
                needWalk = true
            end

            if inserted == MAX_ORES_IN_INVENTORY then
                break
            end

        end

        return needWalk
    end

}

function getLastNoEmptySeedPosition()
    local maxRelPos = Garden.size

    while maxRelPos > 1 and (Garden.seeds[maxRelPos] ~= nil and Garden.seeds[maxRelPos].block == 'air') do
        maxRelPos = maxRelPos - 1
    end

    if maxRelPos < Garden.size then

        Garden.forEach(Garden.getSeedsFrom(function(filter)
            return robotInventory:filter(filter)
        end), function(gardenPosition, seedSlotIndex)
            maxRelPos = math.max(maxRelPos, gardenPosition)
        end)

    end

    return math.min(maxRelPos + 1, Garden.size)
end

---------------------- Command ----------------------

Command = {

    run = function(label)
        local sep = string.find(label, ':')
        local name = string.lower(string.sub(label, 1, sep - 1))
        local params = string.gsub(string.sub(label, sep + 1), "^%s*(.-)%s*$", "%1")

        if name == 'args' then
            Command.options(Command.args(params))
        elseif name == 'cmd' then

            if string.lower(params) == 'shutdown' then
                Command.shutdown()
            elseif string.lower(params) == 'cleanup' then
                Command.cleanup()
            elseif string.lower(params) == 'refresh filter' then
                Command.refreshFilter()
            end

        end

        logger.refresh()
    end,

    args = function(buf)
        local options = {}

        while string.len(buf) > 0 do
            local p = string.find(buf, '=')
            if not p or p == 1 then
                break
            end

            local key = string.sub(buf, 1, p - 1)
            buf = string.sub(buf, p + 1)
            local char = string.sub(buf, 1, 1)
            local val = nil

            if char == '"' then
                buf = string.sub(buf, 2)
                p = string.find(buf, '"')
                if not p then
                    break
                end

                val = string.sub(buf, 1, p - 1)
                buf = string.sub(buf, p + 1)
            elseif char == "'" then
                buf = string.sub(buf, 2)
                p = string.find(buf, "'")
                if not p then
                    break
                end

                val = string.sub(buf, 1, p - 1)
                buf = string.sub(buf, p + 1)
            else
                p = string.find(buf, ' ')

                if not p then
                    val, buf = buf, ''
                else
                    val = string.sub(buf, 1, p - 1)
                    buf = string.sub(buf, p + 1)
                end

            end

            options[key] = val
        end

        if buf ~= "" then
            error("Missing matching quote for " .. buf)
        end

        return options
    end,

    options = function(options)

        local shutdown = options.shutdown
        if shutdown then

            if shutdown == 'y' or shutdown == 'yes' or shutdown == 'true' then
                settings.shutdown = true
            elseif shutdown == 'n' or shutdown == 'no' or shutdown == 'false' then
                settings.shutdown = false
            else
                error('недопустимое значение --shutdown=' .. shutdown)
            end

            Garden.size = Garden.width * Garden.height
        end

        local width = options.x or options.width
        if width then
            Garden.width = tonumber(width)

            if Garden.width == nil then
                error('недопустимое значение --width=' .. width)
            end

            Garden.size = Garden.width * Garden.height
        end

        local height = options.y or options.height
        if height then
            Garden.height = tonumber(height)

            if Garden.height == nil then
                error('недопустимое значение --height=' .. height)
            end

            Garden.size = Garden.width * Garden.height
        end

        local target = options.t or options.target
        if target then
            settings.cropname = string.lower(target)
        end

        local hybrid = options.h or options.hybrid
        if hybrid then

            if hybrid == 'y' or hybrid == 'yes' or hybrid == 'on' then
                settings.hybrid = 100
            elseif hybrid == 'n' or hybrid == 'no' or hybrid == 'off' then
                settings.hybrid = 0
            elseif tonumber(hybrid) then
                settings.hybrid = tonumber(hybrid)
            else
                error('недопустимое значение --hybrid=' .. hybrid)
            end

        end

        if options.growth then
            local growth = tonumber(options.growth)

            if growth == nil then
                error('недопустимое значение --growth=' .. options.growth)
            end

            settings.growth = math.min(growth, MAX_GROWTH - 1)
        end

        if options.gain then
            local gain = tonumber(options.gain)

            if gain == nil then
                error('недопустимое значение --gain=' .. options.gain)
            end

            settings.gain = math.min(gain, 31)
        end

        if options.resistance then
            local resistance = tonumber(options.resistance)

            if resistance == nil then
                error('недопустимое значение --resistance=' .. options.resistance)
            end

            settings.resistance = math.min(resistance, 31)
        end

    end,

    shutdown = function()
        logger.push("Получена команда остановить робота")
        destroyAllDoubleCrops()
        logger.success("Робот остановлен")
    end,

    cleanup = function()
        local energyIsOver = false
        logger.push("Получена команда очистить поле")

        for pos = 1, Garden.size do

            if robotXYZD.go(robotXYZD.XYZDFromPosition(pos, parking.z)) then
                local stats = analizeGardenSeed()

                if stats and stats.block ~= 'air' then

                    if block == 'seed' and stats.size ~= stats.maxSize then
                        robot.useDown()
                    end

                    robot.swingDown()
                    robotInventory:resetCacheFor()
                    Garden.seeds[pos] = {
                        block = 'air',
                        solid = false
                    }
                end

                os.sleep(0.01)

                if robotInventory:isFull() then
                    robotInventory:clean()
                end

                if not energyIsOver then
                    energyIsOver = not checkRobotEnergy()
                end

            end

        end

        if robotInventory:find(filters.pickaxe) ~= nil then

            for pos = 1, Garden.size do

                if robotXYZD.go(robotXYZD.XYZDFromPosition(pos, underground)) then

                    if robot.detectUp() then
                        local pickaxe = robotInventory:find(filters.pickaxe)

                        if pickaxe and robotInventory:use(pickaxe, function()
                            return robotInventory:swingUp()
                        end) then
                            robotInventory:resetCacheFor()
                        else
                            break
                        end

                    end

                    os.sleep(0.01)

                    if robotInventory:isFull() then
                        robotInventory:clean()
                    end

                    if not energyIsOver then
                        energyIsOver = not checkRobotEnergy()
                    end

                end

            end

        end

        robotInventory:clean()
        robotXYZD.go(parking)
        logger.success("Робот остановлен")

    end,

    refreshFilter = function()
        logger.push("Получена команда пересобрать фильтры")

        if chests.filter then

            blacklist = {
                n = 0
            }
            whitelist = {
                n = 0
            }

            createFilter()
        end

    end

}

----------------- resources to work -------------------

function checkToolsInRobot(cropSize)
    local cropsCount, weedExCount, pickaxeCount, hydrantCount, fertilizerCount = 0, 0, 0, 0, 0

    robotInventory:forEach(function(_, item)

        if filters.crop(item) and item.size > 3 then
            cropsCount = cropsCount + item.size
        elseif filters.weedEx(item) then
            weedExCount = weedExCount + item.size
        elseif filters.pickaxe(item) then
            pickaxeCount = pickaxeCount + item.size
        elseif filters.hydration(item) then
            hydrantCount = hydrantCount + item.size
        elseif filters.fertilizer(item) then
            fertilizerCount = fertilizerCount + item.size
        end

    end)

    local result = beeps.crop ~= nil and cropsCount >= cropSize and weedExCount == beeps.weedEx and pickaxeCount ==
                       beeps.pickaxe and hydrantCount == beeps.hydration and
                       (fertilizerCount == beeps.fertilizer or fertilizerCount >= cropSize)

    return result, cropsCount, weedExCount, pickaxeCount, hydrantCount, fertilizerCount
end

function getToolsForWorking() -- пополняем запас жёрдочек в роботе из сундука.
    local full, cropsCount, weedExCount, pickaxeCount, hydrantCount, fertilizerCount = checkToolsInRobot(24)
    local cache = {}

    if full then
        return
    end

    oresCache = {}
    for pos, cropname in pairs(Garden.ores) do
        oresCache[cropname] = true
    end

    for _, chest in pairs({chests.crop, chests.tools, chests.ore, chests.pickaxe}) do
        if cache[chest:guid()] == nil then

            chest:forEach(function(slotIndex, item)

                if filters.crop(item) then
                    local size = math.min(item.size, 56 - cropsCount)

                    if size > 0 then
                        local toolSlotIndex = robotInventory:find(filters.crop) or robotInventory:find(filters.air)
                        chest:suck(slotIndex, toolSlotIndex, size)
                        cropsCount = cropsCount + size
                    end

                elseif filters.fertilizer(item) then

                    local size = math.min(item.size, 64 - fertilizerCount)

                    if size > 0 then
                        local toolSlotIndex = robotInventory:find(filters.fertilizer) or
                                                  robotInventory:find(filters.air)
                        chest:suck(slotIndex, toolSlotIndex, size)
                        fertilizerCount = fertilizerCount + size
                    end

                elseif filters.weedEx(item) then

                    if weedExCount == 0 then
                        local toolSlotIndex = robotInventory:find(filters.air)
                        chest:suck(slotIndex, toolSlotIndex, 1)
                        weedExCount = 1
                    end

                elseif filters.pickaxe(item) then

                    if pickaxeCount == 0 then
                        local toolSlotIndex = robotInventory:find(filters.air)
                        chest:suck(slotIndex, toolSlotIndex, 1)
                        pickaxeCount = 1
                    end

                elseif filters.hydration(item) then

                    if hydrantCount == 0 then
                        local toolSlotIndex = robotInventory:find(filters.air)
                        chest:suck(slotIndex, toolSlotIndex, 1)
                        hydrantCount = 1
                    end

                else

                    for cropname, _ in pairs(getOreSeeds(item)) do
                        oresCache[cropname] = true
                    end

                end

            end)

            cache[chest:guid()] = true
        end
    end

    -- 1. получить палки
    if beeps.crop == nil or beeps.crop ~= cropsCount then
        beeps.crop = cropsCount

        if cropsCount < 3 then -- если палки в роботе кончились
            destroyAllDoubleCrops() -- уничтожим все двойные жёрдочки
            error("ЖEРДОЧКИ КОНЧИЛИСЬ!")
        elseif cropsCount < 24 then -- если после попытки взять жёрдочки из бочки мы имеем меньше жёрдочки чем надо
            logger.push("У робота заканчиваются жёрдочки!")
            computer.beep(1000, 1)
        end

    end

    -- 2. weedEx
    if beeps.weedEx == nil or beeps.weedEx ~= weedExCount then

        if cropsCount == 0 and beeps.weedEx ~= nil then
            logger.push("У робота закончился weedEx!")
            computer.beep(1000, 0.3)
        end

        beeps.weedEx = weedExCount
    end

    -- 3. hydration
    if beeps.hydration == nil or beeps.hydration ~= hydrantCount then

        if hydrantCount == 0 and beeps.hydration ~= nil then
            logger.push("У робота закончился полив!")
            computer.beep(1000, 0.3)
        end

        beeps.hydration = hydrantCount
    end

    -- 4. fertilizer
    if beeps.fertilizer == nil or beeps.fertilizer ~= fertilizerCount then

        if fertilizerCount == 0 and beeps.fertilizer ~= nil then
            logger.push("У робота закончились удобрения!")
            computer.beep(1000, 0.3)
        end

        beeps.fertilizer = fertilizerCount
    end

    -- 5. pickaxe
    if beeps.pickaxe == nil or beeps.pickaxe ~= pickaxeCount then

        if pickaxeCount == 0 and beeps.pickaxe ~= nil then
            logger.push("У робота закончилась кирка!")
            computer.beep(1000, 0.3)
        end

        beeps.pickaxe = pickaxeCount
    end

end

---------------------- ores ---------------------------

function getOreSeeds(item)
    local seeds = {
        n = 0
    }
    local label = string.lower(tostring(item.label))

    for cname, cropores in pairs(seedOres) do
        for _, ore in pairs(cropores) do
            if not seeds[cname] and (ore == label or ("gt.blockores." .. ore .. ".name") == label) then
                seeds[cname] = true
                seeds.n = seeds.n + 1
            end
        end
    end

    return seeds
end

function collectOre(position)
    local pickaxe = robotInventory:find(filters.pickaxe)
    local collect = false

    if pickaxe and robotXYZD.go(robotXYZD.XYZDFromPosition(position, underground)) then

        if robot.detectUp() then

            if robotInventory:use(pickaxe, function()
                return robotInventory:swingUp()
            end) then
                robotInventory:resetCacheFor(filters.ore)
                Garden.ores[position] = nil
                collect = true
            else
                computer.beep(1000, 0.3)
                logger.print('Не могу убрать блок руды')
            end

        else
            Garden.ores[position] = nil
        end

        checkRobotState()
    elseif pickaxe then
        Garden.ores[position] = nil
    end

    return collect
end

function processGardenOres(position)
    local stats = Garden.seeds[position]
    local ore = Garden.ores[position]

    if stats ~= nil and stats.block == 'seed' then

        if ore ~= nil and (ore ~= stats.cropname or stats.size == stats.maxSize) and collectOre(position) then
            ore = nil
        end

        if ore == nil and stats.size + 1 == stats.maxSize then -- поставить блок
            local oreIndex = robotInventory:find(function(item)
                return getOreSeeds(item)[stats.cropname]
            end)

            if oreIndex ~= nil and robotXYZD.go(robotXYZD.XYZDFromPosition(position, underground)) then
                robotInventory:place(oreIndex, robot.placeUp)
                Garden.ores[position] = stats.cropname

                checkRobotState()
            end

        end

    elseif ore ~= nil then
        collectOre(position)
    end

end

---------------------- cond ----------------------

function existsOreBlock(stats)
    return stats.cropname == settings.cropname or seedOres[stats.cropname] == nil or oresCache[stats.cropname] ~= nil
end

function inBlackList(stats)
    return settings.cropname ~= nil and stats.cropname ~= settings.cropname and not whitelist[stats.cropname] and
               (settings.hybrid <= (uniqueHybrids[stats.cropname] or 0) or blacklist[stats.cropname] ~= nil)

end

function seedIsWeed(stats)
    return not stats or stats.growth == 0 or stats.gain == 0 or stats.level == 0 or stats.growth >= MAX_GROWTH or
               weeds[stats.cropname] ~= nil
end

function seedIsTarget(stats)

    return stats.cropname == settings.cropname and stats.resistance <= settings.resistance and stats.growth >=
               settings.growth and stats.gain >= settings.gain and stats.growth < MAX_GROWTH

end

function seedMayBePlanted(stats)
    if seedIsWeed(stats) or not existsOreBlock(stats) then
        return false
    end

    local success = false

    Garden.forEach(Garden.getSeedsFrom(function()
        return {
            [1] = stats
        }
    end), function()
        success = true
    end)

    return success
end

---------------------- seeds ----------------------

function analizeGardenSeed()
    local position = robotXYZD.currentPosition()

    if not robot.detectDown() then
        Garden.seeds[position] = {
            block = 'air',
            solid = false
        }
        return Garden.seeds[position]
    end

    local analyzeResult = geo.analyze(0) -- анализируем блок под роботом
    local block = analyzeResult.name
    local cropname = analyzeResult["crop:name"]
    local stats = {}

    if cropname == 'weed' then
        stats.block = 'weed'
    elseif cropname ~= nil then
        stats.block = 'seed'

        stats.cropname = string.lower(cropname)
        stats.gain = math.floor(analyzeResult["crop:gain"])
        stats.growth = math.floor(analyzeResult["crop:growth"])
        stats.resistance = math.floor(analyzeResult["crop:resistance"])

        stats.fertilizer = math.floor(analyzeResult["crop:fertilizer"])
        stats.hydration = math.floor(analyzeResult["crop:hydration"])
        stats.weedEx = math.floor(analyzeResult["crop:weedex"])

        stats.size = analyzeResult["crop:size"]
        stats.maxSize = analyzeResult["crop:maxSize"]

        stats.level = createSeedLevel(stats.growth, stats.gain, stats.resistance)

        if customSeedsMaxSize[stats.cropname] ~= nil then
            stats.maxSize = customSeedsMaxSize[stats.cropname]
        end

    elseif block == IC2_BLOCK_CROP then
        local place = Garden.seeds[position]

        if place == nil then
            stats.block = 'crop'
        else
            stats.block = place.block ~= 'double-crop' and 'crop' or 'double-crop'
            stats.fertilizer = place.fertilizer
            stats.hydration = place.hydration
            stats.weedEx = place.weedEx
        end

    else
        stats.block = 'air'
        stats.solid = block ~= "minecraft:air"
    end

    Garden.seeds[position] = stats

    return stats
end

function convertSlotToStats(slot)

    if slot.block == 'seed' then
        return slot
    end

    if not filters.seed(slot) or slot.crop == nil then
        return nil
    end

    local stats = {}
    stats.block = 'seed'
    stats.cropname = string.lower(slot.crop.name)
    stats.gain = math.floor(slot.crop.gain)
    stats.growth = math.floor(slot.crop.growth)
    stats.resistance = math.floor(slot.crop.resistance)

    stats.fertilizer = 0
    stats.hydration = 0
    stats.weedEx = 0

    stats.size = 1
    stats.maxSize = 100

    stats.level = createSeedLevel(stats.growth, stats.gain, stats.resistance)

    return stats
end

function createSeedLevel(growth, gain, resistance)
    return growth + gain - resistance
end

---------------------- crops ----------------------

function useFertilizer(stats)

    if stats ~= nil and stats.block == 'seed' and stats.size ~= stats.maxSize then
        local hydrationIndex = nil
        local fertilizerIndex = nil

        if stats.hydration == nil or stats.hydration < 10 then
            hydrationIndex = robotInventory:find(filters.hydration)
        end

        if stats.fertilizer == nil or stats.fertilizer < 10 then
            fertilizerIndex = robotInventory:find(filters.fertilizer)
        end

        if hydrationIndex ~= nil and fertilizerIndex ~= nil then
            robot.select(hydrationIndex)

            inventory.equip()
            robot.useDown()

            robot.select(fertilizerIndex)

            inventory.equip()
            robot.useDown()

            robot.select(hydrationIndex)
            inventory.equip()

            robotInventory:updateSlot(hydrationIndex)
            robotInventory:updateSlot(fertilizerIndex)

            stats.hydration = 200
            stats.fertilizer = math.min(stats.fertilizer + 100, 200)
        elseif hydrationIndex ~= nil then
            robotInventory:use(hydrationIndex, robot.useDown)
            stats.hydration = 200
        elseif fertilizerIndex ~= nil then
            robotInventory:use(fertilizerIndex, robot.useDown)
            stats.fertilizer = math.min(stats.fertilizer + 100, 200)
        end

    end

end

function placeDoubleCrops() -- ставит новые палки
    local position = robotXYZD.currentPosition()
    local stats = Garden.seeds[position] or {
        block = 'air'
    }

    if not canPlaceDoubleCrops(position) then
        breakCrops()
    elseif stats.block ~= 'double-crop' then
        breakCrops()

        local cropIndex = robotInventory:find(function(item)
            return filters.crop(item) and item.size > 2
        end)

        if cropIndex ~= nil then

            robotInventory:use(cropIndex, function()
                robot.useDown()
                robot.useDown()
            end)

            Garden.seeds[position] = {
                block = 'double-crop'
            }

            local weedExIndex = robotInventory:find(filters.weedEx)

            if weedExIndex ~= nil then
                robotInventory:use(weedExIndex, robot.useDown)
            end

        end

    end

end

function breakCrops()
    local position = robotXYZD.currentPosition()
    local stats = Garden.seeds[position] or {
        block = 'air'
    }

    if stats.block ~= 'air' then
        robot.swingDown()
        robotInventory:resetCacheFor(filters.crop)

        Garden.seeds[position] = {
            block = 'air'
        }
    end

end

function canPlaceDoubleCrops(position)

    if isMotherPosition(position) or Garden.seeds[position] ~= nil and Garden.seeds[position].solid then
        return false
    end

    local places = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}}
    local halfX = math.floor(Garden.width / 2)
    local sides = 0

    for i = 1, 4 do
        local posX = robotXYZD.x + places[i][1]
        local posY = robotXYZD.y + places[i][2]

        if posX >= -halfX and posX <= halfX and posY > 0 and posY <= Garden.height then
            local stats = Garden.seeds[robotXYZD.positionFromXYZD(posX, posY)]

            if stats and stats.block == 'seed' and (stats.size == stats.maxSize or stats.size >= 3) then
                sides = sides + 1

                if sides == 2 then
                    return true
                end

            end

        end

    end

    return false
end

function destroyAllDoubleCrops(energyIsOver) -- уничтожим все двойные жердочки

    for pos = 1, Garden.size do

        if robotXYZD.go(robotXYZD.XYZDFromPosition(pos, parking.z)) then
            local stats = analizeGardenSeed()

            if stats and stats.block ~= 'air' and (stats.block ~= 'seed' or seedIsWeed(stats)) then

                robot.swingDown()
                robotInventory:resetCacheFor()
                Garden.seeds[pos] = {
                    block = 'air'
                }

            end

            os.sleep(0.01)

            if robotInventory:isFull() then
                robotInventory:clean()
            end

            if not energyIsOver then
                energyIsOver = not checkRobotEnergy()
            end

        end

    end

    robotXYZD.go(parking)
end

function processGardenSeeds(position) -- функция анализа и обработки семечки.

    if not robotXYZD.go(robotXYZD.XYZDFromPosition(position, parking.z)) then
        Garden.seeds[position] = {
            block = 'air',
            solid = true
        }
        return
    end

    local previousBlock = nil

    if Garden.seeds[position] ~= nil then
        previousBlock = Garden.seeds[position].block
    end

    local stats = analizeGardenSeed()
    local block = stats.block

    if stats.solid then
        return
    end

    if isMotherPosition(position) then
        local seedSlotIndex = Garden.findBestSeedsInInventory(position)

        if seedSlotIndex then

            if robotInventory:find(function(item)
                return filters.crop(item) and item.size > 2
            end) ~= nil then
                local slotStats = convertSlotToStats(robotInventory:get(seedSlotIndex))

                if block == 'seed' then

                    if slotStats.cropname == stats.cropname then
                        logger.print(
                            "Заменяем: " .. stats.cropname .. " (" .. stats.growth .. " " .. stats.gain .. " " ..
                                stats.resistance .. ") на (" .. slotStats.growth .. " " .. slotStats.gain .. " " ..
                                slotStats.resistance .. ")")
                    elseif slotStats.cropname == settings.cropname then
                        logger.print("Заменяем: " .. stats.cropname .. " на " .. slotStats.cropname .. " (" ..
                                         slotStats.growth .. " " .. slotStats.gain .. " " .. slotStats.resistance .. ")")
                    else
                        logger.print(
                            "Заменяем: " .. stats.cropname .. " (" .. stats.growth .. " " .. stats.gain .. " " ..
                                stats.resistance .. ") на " .. slotStats.cropname .. " (" .. slotStats.growth .. " " ..
                                slotStats.gain .. " " .. slotStats.resistance .. ")")
                    end

                else
                    logger.print("Садим: " .. slotStats.cropname .. " (" .. slotStats.growth .. " " ..
                                     slotStats.gain .. " " .. slotStats.resistance .. ")")
                end

                robotInventory:plantSeed(seedSlotIndex, stats)

                analizeGardenSeed()
            else
                logger.print(
                    "Не получилось заменить родительское растение: нет жердочек")
            end

        elseif block ~= 'seed' and block ~= 'air' then
            logger.print("Зачищаем материнский кроп")
            breakCrops()
        end

    elseif block == 'seed' then
        local label = stats.cropname .. " (" .. stats.growth .. " " .. stats.gain .. " " .. stats.resistance .. ")"

        if stats.size == stats.maxSize then -- созрело
            logger.print("Собираем " .. label)
            placeDoubleCrops()
        elseif seedIsWeed(stats) then -- мусор
            logger.print("Негодное растение: " .. label)
            placeDoubleCrops()
        elseif inBlackList(stats) then -- в чёрном списке (если выключены гибриды также находятся в чёрном списке)
            logger.print("В чёрном списке: " .. label)
            placeDoubleCrops()
        elseif seedOres[stats.cropname] and stats.size + 1 == stats.maxSize and
            (not existsOreBlock(stats) or not robotInventory:find(filters.pickaxe)) then

            if not robotInventory:find(filters.pickaxe) then
                logger.print("Нет кирки для " .. stats.cropname)
            else
                logger.print("Нет рудного блока для " .. stats.cropname)
            end

            robot.useDown()
            robotInventory:resetCacheFor()

            placeDoubleCrops()
        elseif stats.cropname == settings.cropname and not seedIsTarget(stats) and not seedMayBePlanted(stats) then
            logger.print("Негодное растение: " .. label)
            placeDoubleCrops()
        elseif previousBlock ~= block then

            if stats.cropname ~= settings.cropname then
                logger.print("Гибрид: " .. label)
            else
                logger.print("Новое растение: " .. label)
            end

        end

    else
        placeDoubleCrops()
    end

    useFertilizer(Garden.seeds[position])
    checkRobotState()

end

---------------------- основной скрипт ----------------------
function main(...)

    local _, options = shell.parse(...)
    Command.options(options)

    logger.refresh()

    ------------- проверяем работоспособность geolyzer -------------

    local g0, g1 = component.geolyzer.analyze(0)

    if g0 == nil and g1 ~= nil then
        error(
            "open computers geolyzer не работает\nна версии GTNH 2.1.2.1.\nОбновите моды. См. строку 2736 кода")

        -- АЛЬТЕРНАТИВА: установить новейшую версию. OpenComputers исправлен уже на 2.1.2.3-qf
        -- gtnh.miraheze.org/wiki/Installing_and_Migrating
        -- downloads.gtnewhorizons.com/Multi_mc_downloads/
        --
        -- Обновление баговоной версии ОС на рабочую (бэкапим старые моды на всякий случай и качаем всё это)
        -- ОС - jenkins.usrv.eu:8080/job/OpenComputers/ четвертая ссылка
        -- Nei - jenkins.usrv.eu:8080/job/NEI/ третья ссылка
        -- CodeChickenCore - jenkins.usrv.eu:8080/job/CodeChickenCore/ третья ссылка
    end

    ------------- проверяем наличие лопатки -------------

    logger.push("Шаг 1. Проверяю наличие лопатки")
    robotInventory = Inventory:new()

    local item = robotInventory:use(1, function()
        return robotInventory:get(1)
    end)

    if item == nil or item.name ~= "berriespp:itemSpade" then
        error("Нет лопатки в слоте для инструмента!")
    end

    ------------- кэшируем сундуки -------------

    logger.push("Шаг 2. Проверяю сундуки\n| Сундук | Координата |")

    for index, chestName in pairs({'product', 'trashcan', 'seed', 'hybrid', 'filter', 'crop', 'tools', 'ore', 'command',
                                   'pickaxe'}) do
        local xyzd = chests[chestName]
        local guid = xyzd.x .. ' ' .. xyzd.y .. ' ' .. xyzd.z .. ' ' .. xyzd.dir

        logger.push(chestName .. " - " .. guid)

        if chests[guid] == nil then
            robotXYZD.go(xyzd)

            if inventory.getInventorySize(3) ~= nil then
                chests[guid] = Chest:new(xyzd)
            elseif xyzd.required == nil or xyzd.required == true then
                robotXYZD.go(parking)
                error("Не найден сундук '" .. chestName .. "'!")
            end

        end

        chests[chestName] = chests[guid]
    end

    ------------- получаем инструменты -------------

    logger.push("Шаг 3. Получаю инструменты")

    robotInventory:clean()
    getToolsForWorking()

    ------------- анализируем поле / ищем целевое растение -------------
    logger.push('Шаг 4. Aнализирую поле перед работой')

    for pos = 1, Garden.size do

        if robotXYZD.go(robotXYZD.XYZDFromPosition(pos, parking.z)) then
            local stats = analizeGardenSeed()

            if stats.block == 'weed' or stats.block == 'crop' then
                robot.swingDown()
                robotInventory:resetCacheFor()
                Garden.seeds[pos] = {
                    block = 'air',
                    solid = false
                }
            elseif isMotherPosition(pos) then

                if settings.cropname == nil and stats.block == 'seed' then
                    settings.cropname = stats.cropname
                    logger.refresh()
                end

            end

            checkRobotState()
        end

    end

    if robotInventory:find(filters.pickaxe) ~= nil then

        for pos = 1, Garden.size do

            if robotXYZD.go(robotXYZD.XYZDFromPosition(pos, underground)) then

                if robot.detectUp() then
                    local pickaxe = robotInventory:find(filters.pickaxe)

                    if pickaxe and robotInventory:use(pickaxe, function()
                        return robotInventory:swingUp()
                    end) then
                        robotInventory:resetCacheFor()
                    else
                        Garden.ores[pos] = 'undefined'
                    end

                end

                checkRobotState()
            end

        end

        robotInventory:clean()
    else

        for pos = 1, Garden.size do
            Garden.ores[pos] = 'undefined'
        end

    end

    ------------- если поле пустое ищем целевое растение в главном сундуке -------------

    if not settings.cropname then
        local _, slot = chests.seed:find(function(item)
            return filters.seed(item) and not seedIsWeed(convertSlotToStats(item))
        end)

        if slot then
            settings.cropname = convertSlotToStats(slot).cropname
            logger.refresh()
        end

    end

    if not settings.cropname then
        robotXYZD.go(parking)
        error('Не найдено растений')
    end

    ------------- генерируем чёрный список -------------

    logger.push('Шаг 5. Создаю фильтры')

    if chests.filter then
        createFilter()
    end

    ------------- возвращаемся на исходное место -------------

    logger.push("Шаг 6. Приступаю к работе");
    while true do -- главный цикл

        getToolsForWorking()
        local existsSeeds, fullSlots = Garden.suckSeedsFromChest(1)

        -------------------------------------------

        for pos = 1, Garden.size do

            if pos > getLastNoEmptySeedPosition() then

                if not fullSlots then
                    break
                else
                    existsSeeds, fullSlots = Garden.suckSeedsFromChest(pos)

                    if not existsSeeds then
                        break
                    end

                end

            end

            processGardenSeeds(pos)
        end

        robotInventory:clean()

        -------------------------------------------

        if robotInventory:find(filters.pickaxe) and Garden.suckOresFromChest(1) then

            for pos = 1, Garden.size do
                processGardenOres(pos)
            end

            robotInventory:clean()
        end

        -------------------------------------------

        robotXYZD.go(parking)

        local sleep = math.floor(35 - (getLastNoEmptySeedPosition() / 2 - 1) / 2 * 5)

        if sleep > 0 then
            os.sleep(sleep)
        else
            os.sleep(3)
        end

    end

end

local function errorFormatter(msg)
    return {
        msg = msg:gsub("^[^%:]+%:[^%:]+%: ", ""),
        trace = debug.traceback(msg)
    }
end

local ok, err = xpcall(main, errorFormatter, ...)

if not ok then
    term.write("\n" .. err.msg)

    local file = io.open("/home/crop_stats.log", "a")
    file:write(err.trace .. "\n")
    file:close()

    computer.beep(1000, 0.3)
    computer.beep(1000, 0.3)
    computer.beep(1000, 0.3)

    if settings.shutdown then
        os.sleep(10)
        computer.shutdown()
    end
end

-- История версий:

-- Версия 1.1.3
-- Устранена уязвимость к коллизиям. Нахождение игрока на пути следования робота больше не приводит к потере роботом маршрута. Робот после столкновения с игроком замирает на секунду, после чего продолжает попытку движения
-- Добавлена история версий в файл скрипта робота

-- Версия 2.0.0
-- Полностью переписан скрипт
-- Добавлена возможность менять размер поля
-- Изменена сортировка продукции
-- Добавлена возможность разводить гибриды (другие виды при скрещивании)
-- Изменён алгоритм определения материнского растения (ищет на поле, потов в инветроре робота а потом в рабочем сундуке)

-- Версия 2.0.1
-- Можно указать удобрения полив и weedEx
-- Можно указать список ненужных гибридов
-- Добавлена оптимизация для внешних сундуков
-- Изменён алгоритм посадки. Теперь садит максимально выгодно

-- Версия 2.0.2
-- Поменял алгоритм сортировки
-- Упростил алгоритм определения семян для посадки

-- Версия 2.0.3
-- Робот неверно определял окончание палок в сундуке
-- Добавил возможность самому указывать распределение предметов в сундуках

-- Версия 2.0.4
-- Упростил поиск блоков в инвенторе
-- Добавил возможность устанавливать руду под растения
-- Чёрный список можно формировать не только с помощью семян
-- Теперь можно размещать в центре поля Crop-Matron
-- Изменилось кол-во сундуков необходимых для работы
-- Изменилось изначальное положение робота
-- Если у робота не будет кирки, тогда нижнюю часть можно игнорировать
-- Теперь Ardite berry собирается на предпоследнем уровне

-- Версия 2.0.5
-- Исправил баг неправильной сортировки целевых семян

-- Версия 2.1.0
-- Переработал работу робота
-- Теперь робот сбивает гибриды если у робота нет рудного блока для его выращивания

-- Версия 2.1.1
-- Исправил баг с фильтрацией рабочего сундука
-- Исправил баг с расставлением руды. теперь фильтр учитывает блоки включающие в названии block, ore, and cobblestone

-- Версия 2.1.2
-- Исправил баг с сорняками на материнских растениях

-- Версия 2.1.12
-- Исправил баг с сортировкой рабочего сундука для 2.1.1 версии GTNH

-- Версия 2.1.14
-- Исправлен баг с хождением робота при низком tps

-- Версия 2.1.15
-- Исправлен баг с сбивание блоков руды при низком tps

-- Версия 2.1.16
-- Изменён принцип работы settings.resistance. Теперь он указывает не минимальное значение, а максимальное для этого стата

-- Версия 2.1.17
-- Исправлен баг с не просканированными семенами в сундуке с гибридами

-- Версия 2.1.18
-- Добавлена руда для space plant

-- Версия 2.1.19
-- Исправлен баг с сундуком для кирок

-- Версия 2.1.20
-- Исправлен баг с отображением ошибки

-- Версия 2.1.21
-- Исправлен баг с посадкой растения в gtnh >= 2.1.2.0 смотрите описание settings.seedPlaceMethod

-- Версия 2.1.22
-- Исправлен алгоритм очистки сундука L1 возникшая из-за увеличения стака у семян

-- Версия 2.1.23
-- Дописал несколько примеров работы с аргументами в документацию

-- Версия 2.1.24 (автор дополнения: Denactive#4495)
-- Дописал предупреждение о баге geolyzer на GTNH 2.1.2.1
-- Добавил комментарии по изменению базовой архитектуры станции
-- Исправлен баг с невозможностью робота взять кирку из сундука для кирок - вместо этого он брал ее только из сундука tools
-- Добавлена ссылка на обзор этого скрипта от ZARATUSTRA
-- Добавлен аргумент shutdown

-- Версия 2.1.25
-- Исправлена ошибка при отсутствии сундука для чёрного списка

-- Версия 2.1.26
-- Изменён алгоритм поиска семян в сундуке

-- Версия 2.1.27
-- Для reactoria добавил ещё один блок

-- Версия 2.1.28
-- Добавил ссылку на скрины от ThIbNi т.е. на моих неверная высота поля
