# Properties, sections, elements

## Properties

### Basic Types

```php
(new \CIBlockProperty)->Add([
    'IBLOCK_ID'     => $iblockId,
    'NAME'          => 'Author',
    'CODE'          => 'AUTHOR',      // required! ORM won't see it without CODE
    'PROPERTY_TYPE' => 'S',            // S-string, N-number, L-list, F-file, E-element, G-section
    'MULTIPLE'      => 'N',
]);
```

### List (`L`)

```php
$propId = (new \CIBlockProperty)->Add([
    'IBLOCK_ID' => $iblockId, 'NAME' => 'Source', 'CODE' => 'SOURCE',
    'PROPERTY_TYPE' => 'L', 'MULTIPLE' => 'N',
]);

$enum = new \CIBlockPropertyEnum();
$enum->Add(['PROPERTY_ID' => $propId, 'VALUE' => 'Reuters', 'XML_ID' => 'reuters', 'SORT' => 10]);
```

### User Types (`USER_TYPE`)

- `USER_TYPE = 'HTML'`, `PROPERTY_TYPE = 'S'` — HTML editor.
- `USER_TYPE = 'directory'`, `PROPERTY_TYPE = 'S'` + `USER_TYPE_SETTINGS = ['TABLE_NAME' => 'b_<hl_table>']` — value from Highload block, `UF_XML_ID` is stored.
- `USER_TYPE = 'DateTime'`, `PROPERTY_TYPE = 'S'` — date-time.

**Highload blocks** (dictionaries, directory properties): use skill `bitrix-highloadblock`. ORM entities come from HL `compileEntity` (not iblock `IblockTable::compileEntity`).

## Sections via ORM

```php
$sectionClass = \Bitrix\Iblock\Model\Section::compileEntityByIblock('News');

$parent = $sectionClass::createObject()
    ->setIblockId($iblockId)
    ->setName('Events')
    ->setCode('events')
    ->set('UF_MANAGER', 'John Doe') // UF fields via set('UF_*', ...)
    ->setActive(true)
    ->save();

$child = $sectionClass::createObject()
    ->setIblockId($iblockId)
    ->setName('Exhibitions')
    ->setCode('exhibitions')
    ->setIblockSectionId($parent->getObject()->getId())
    ->save();
```

Reading with parent:

```php
$section = $sectionClass::query()
    ->setSelect(['*', 'PARENT_SECTION', 'UF_*'])
    ->where('CODE', 'exhibitions')
    ->fetchObject();

$section->getParentSection()?->getName();
```

Deletion:

- **`CIBlockSection::Delete($id)`** — recursively deletes sub-sections and elements, clears cache and search index.
- `$section->delete()` — only deletes the section itself (children will become orphaned). Use with caution.

## Elements via ORM

### Creation

```php
$elementClass = \Bitrix\Iblock\Elements\ElementNewsTable::class;

$element = $elementClass::createObject()
    ->setName('Security Update')
    ->setCode('security-update')
    ->setActive(true)
    ->setIblockSectionId($parentSectionId)
    ->set('AUTHOR', 'Jane Smith')  // string
    ->set('SOURCE', $enumId);       // list — ID of value from CIBlockPropertyEnum

$result = $element->save();
if (!$result->isSuccess()) { /* errors */ }
```

### Multiple Properties

```php
$element
    ->addTo('TAGS', 'security')
    ->addTo('TAGS', '2026');

$element->removeAll('TAGS');      // clear all
$element->removeAllBy('TAGS', 'security');
```

### File Properties

ORM requires `PropertyValue` — it contains file `ID` + description.

```php
use Bitrix\Iblock\ORM\PropertyValue;

$fileId = \CFile::SaveFile(
    \CFile::MakeFileArray($_SERVER['DOCUMENT_ROOT'] . '/upload/img.png'),
    'iblock',
);

\CFile::ResizeImage($fileId, ['width' => 300, 'height' => 300], BX_RESIZE_IMAGE_PROPORTIONAL, true);

$element
    ->set('PHOTO',   new PropertyValue($fileId, 'Main Photo'))
    ->addTo('GALLERY', new PropertyValue($otherId, 'Second Shot'));
```

### Element Relations (`E`, `G`)

```php
$element->set('RELATED_ARTICLE', $otherElementId);
$element->set('MANUFACTURER', $sectionId);
```
