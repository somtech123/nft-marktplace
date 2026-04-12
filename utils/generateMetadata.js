const fs = require("fs");
const path = require("path");

function createMetadata({ name, description, image, attributes = [] }) {
  return { name, description, image, attributes };
}

function saveMetadata(metadata, filename) {
  const dir = path.join(__dirname, "metadata");

  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir);
  }

  const filePath = path.join(dir, `${filename}.json`);
  fs.writeFileSync(filePath, JSON.stringify(metadata, null, 2));
  console.log(`saved: ${filePath}`);
}

const nftItems = [
  {
    name: "Angry Ape",
    description: "A very angry ape NFT.",
    image: "ipfs://bafybeidds4y4nqcvshgsibvy3d3flgbr6efs5igahvwo7woebziyv6tx6y",
    attributes: [
      { trait_type: "Level", value: 1 },
      { trait_type: "Mood", value: "Angry" },
      { trait_type: "Rarity", value: "Common" },
    ],
  },
  {
    name: "Wild Trio",
    description:
      "A unique NFT featuring a monkey, an ape, and a squirrel together in a vibrant scene.",
    image: "ipfs://bafybeiavysix2djk5hsrgchn6nuqnzihdhdypkaset5spnwjbpy56tabou",
    attributes: [
      {
        trait_type: "Animals",
        value: "Monkey, Ape, Squirrel",
      },
      {
        trait_type: "Monkey",
        value: "Present",
      },
      {
        trait_type: "Ape",
        value: "Present",
      },
      {
        trait_type: "Squirrel",
        value: "Present",
      },
      {
        trait_type: "Background",
        value: "Nature",
      },
      {
        trait_type: "Rarity",
        value: "Uncommon",
      },
    ],
  },
  {
    name: "Kingpin Ape",
    description:
      "A dominant ape boss wearing a crown and smoking, representing power, street authority, and underground influence.",
    image: "ipfs://bafybeicijhrgrhutcuyx3sul66bmg2zclhkvxam5z3im6tz3ohipjcu32y",
    attributes: [
      {
        trait_type: "Species",
        value: "Ape",
      },
      {
        trait_type: "Headwear",
        value: "Crown",
      },
      {
        trait_type: "Accessory",
        value: "Cigarette",
      },
      {
        trait_type: "Style",
        value: "Gangster",
      },
      {
        trait_type: "Mood",
        value: "Dominant",
      },
      {
        trait_type: "Rarity",
        value: "Legendary",
      },
    ],
  },
  {
    name: "Gentleman Ape",
    description:
      "A refined and gentle ape dressed in a stylish suit, embodying elegance, calmness, and sophistication.",
    image: "ipfs://bafybeieajobdfq2tlktileuycdwegwaivcad3nhnn2pnafw5rugbvtwkey",
    attributes: [
      {
        trait_type: "Species",
        value: "Ape",
      },
      {
        trait_type: "Outfit",
        value: "Suit",
      },
      {
        trait_type: "Style",
        value: "Gentleman",
      },
      {
        trait_type: "Mood",
        value: "Calm",
      },
      {
        trait_type: "Personality",
        value: "Elegant",
      },
      {
        trait_type: "Rarity",
        value: "Rare",
      },
    ],
  },
];

nftItems.forEach((item, index) => {
  const metadata = createMetadata(item);
  saveMetadata(metadata, `${index}`);
});
